terraform {
  required_version = ">= 0.15.1"
  required_providers {
    azurerm = {
      version = ">=3.5"
    }
    vault = {
      version = ">=2.13"
    }
  }
}

locals {
  connections = {
    StorageV2        = ["blob", "file", "web", "dfs", "queue", "table"],
    BlockBlobStorage = ["blob", "web", "dfs"],
    BlobStorage      = ["blob", "dfs"],
    FileStorage      = ["file"]
  }


  ip_range_filter = distinct(flatten(concat([
    for ip_range in var.ip_range_filter :
    tonumber(split("/", ip_range)[1]) == 32 ? [split("/", ip_range)[0]] :
    tonumber(split("/", ip_range)[1]) == 31 ? [cidrhost(ip_range, 0), cidrhost(ip_range, 1)] : [ip_range]
  ])))

  selected_connections = local.connections[var.account_kind]
}

resource "azurerm_storage_account" "stg" {
  name                             = "stdsg${replace(var.workload_name, "-", "")}${var.environment}${var.region}"
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  account_kind                     = var.account_kind
  access_tier                      = var.access_tier
  is_hns_enabled                   = var.is_hns_enabled
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  enable_https_traffic_only        = true
  min_tls_version                  = "TLS1_2"
  nfsv3_enabled                    = var.nfsv3_enabled
  large_file_share_enabled         = var.account_kind == "FileStorage" ? true : var.large_file_share_enabled
  cross_tenant_replication_enabled = false

  dynamic "blob_properties" {
    for_each = var.account_kind != "FileStorage" ? ["1"] : []
    content {
      versioning_enabled = var.versioning_enabled

      dynamic "delete_retention_policy" {
        for_each = var.soft_delete_retention_days != 0 && var.account_kind != "FileStorage" ? [1] : []
        content {
          days = var.soft_delete_retention_days
        }
      }
      dynamic "container_delete_retention_policy" {
        for_each = var.soft_delete_retention_days != 0 && var.account_kind != "FileStorage" ? [1] : []
        content {
          days = var.soft_delete_retention_days
        }
      }

      dynamic "cors_rule" {
        for_each = var.cors_rules
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = concat(local.ip_range_filter, module.firewall_lookup.ip_ranges)
    virtual_network_subnet_ids = concat(var.firewall_subnet_ids, module.firewall_lookup.subnet_ids)
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "private" {
  for_each            = toset(local.selected_connections) != null && var.private_endpoint_subnet_id != "" ? toset(local.selected_connections) : []
  name                = "${azurerm_storage_account.stg.name}-${each.value}-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_dns_zone_group {
    name                 = each.value
    private_dns_zone_ids = ["/subscriptions/subid/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/privatelink.${each.value}.core.windows.net"]
  }

  private_service_connection {
    name                           = "${azurerm_storage_account.stg.name}-${each.value}-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.stg.id
    subresource_names              = [each.value]
    is_manual_connection           = false
  }

  tags = var.tags
}

data "azurerm_monitor_diagnostic_categories" "stg" {
  resource_id = azurerm_storage_account.stg.id
}

resource "azurerm_monitor_diagnostic_setting" "stg" {
  name                       = "all_diag"
  target_resource_id         = azurerm_storage_account.stg.id
  log_analytics_workspace_id = module.re_workspace.workspace

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.stg.log_category_types
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.stg.metrics
    content {
      category = metric.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }
}

data "azurerm_client_config" "sp" {
}

resource "azurerm_role_assignment" "storage_blob_data_owner" {
  scope                = azurerm_storage_account.stg.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.sp.object_id
}

resource "vault_generic_secret" "azurerm_storage_account_creds" {
  path = var.vault_secret_path

  data_json = <<VAULT_VALUE
  {
    "primary_blob_endpoint": "${azurerm_storage_account.stg.primary_blob_endpoint}",
    "primary_access_key": "${azurerm_storage_account.stg.primary_access_key}",
    "primary_connection_string": "${azurerm_storage_account.stg.primary_connection_string}",
    "secondary_access_key": "${azurerm_storage_account.stg.secondary_access_key}",
    "secondary_connection_string": "${azurerm_storage_account.stg.secondary_connection_string}"
  }
  VAULT_VALUE
}