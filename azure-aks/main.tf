terraform {
  required_version = ">=0.15.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = ">=1.4.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "primary" {}

data "azuread_group" "aks_cluster_admins" {
  for_each     = toset(var.aks_cluster_admins_ad_group)
  display_name = each.key
}

resource "azurerm_role_assignment" "aks_rbac_admin" {
  for_each             = data.azuread_group.aks_cluster_admins
  scope                = azurerm_kubernetes_cluster.aks_cluster.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azuread_group.aks_cluster_admins[each.key].object_id
}

resource "azurerm_user_assigned_identity" "cluster_identity" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "id-${var.workload_name}-${var.environment}-${module.region_mapping.region}"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  # name               = "00000000-0000-0000-0000-000000000000" # will be auto created
  scope                = "/subscriptions/SUBID/resourceGroups/networking/providers/Microsoft.Network/RG/privatelink.eastus.azmk8s.io"
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster_identity.principal_id
}

resource "azurerm_role_assignment" "network_contributor" {
  # name               = "00000000-0000-0000-0000-000000000000" # will be auto created
  scope                = split("/subnets/", var.subnet_id)[0]
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster_identity.principal_id
}


resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                            = "aks-${var.workload_name}-${var.environment}-${var.region}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  dns_prefix                      = "${var.workload_name}-${var.environment}"
  private_cluster_enabled         = true
  private_dns_zone_id             = "/subscriptions/SUBID/resourceGroups/networking/providers/Microsoft.Network/RG/privatelink.${var.location}.azmk8s.io"
  sku_tier                        = "Paid"
  kubernetes_version              = var.kubernetes_version
  api_server_authorized_ip_ranges = []
  tags                            = var.tags

  azure_policy_enabled              = true
  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = var.oidc_issuer_enabled

  dynamic "oms_agent" {
    for_each = var.app_insights_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.app_insights_workspace_id
    }
  }

  default_node_pool {
    name                 = var.node_name
    node_count           = var.node_count
    vm_size              = var.node_vm_size
    zones                = var.zones
    enable_auto_scaling  = var.enable_auto_scaling
    max_count            = var.auto_scaling_max_count
    min_count            = var.auto_scaling_min_count
    max_pods             = var.max_pods
    orchestrator_version = var.kubernetes_version
    os_disk_size_gb      = var.os_disk_size_gb
    # os_disk_type          = "Managed"
    # type                  = "VirtualMachineScaleSets"
    vnet_subnet_id = var.subnet_id
    # enable_node_public_ip = false
    ultra_ssd_enabled = var.ultra_ssd_enabled
    node_labels       = var.node_labels
    node_taints       = []
    tags              = var.tags
  }

  identity {
    # user assigned identity is required for private zone linking
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster_identity.id]
  }

  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = "kubenet" # "azure" # "kubenet" # azure will need a lot more IP space
    network_policy     = "calico"  # "azure" # "calico"
    outbound_type      = "userAssignedNATGateway"
    docker_bridge_cidr = "10.251.0.0/16"
    pod_cidr           = "10.252.0.0/16"
    service_cidr       = "10.253.0.0/16"
    dns_service_ip     = "10.253.0.10"
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  timeouts {
    create = "120m"
    update = "120m"
    delete = "120m"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].tags,
      tags
    ]
  }

  depends_on = [
    azurerm_role_assignment.private_dns_zone_contributor,
    azurerm_role_assignment.network_contributor
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "additional_node_pools" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  zones                 = each.value["zones"]
  vm_size               = each.value["vm_size"]
  os_disk_size_gb       = each.value["os_disk_size_gb"]
  node_count            = each.value["node_count"]
  vnet_subnet_id        = var.subnet_id # At this time the vnet_subnet_id must be the same for all node pools in the cluster https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool#vnet_subnet_id
  enable_auto_scaling   = each.value["enable_auto_scaling"]
  min_count             = each.value["auto_scaling_min_count"]
  max_count             = each.value["auto_scaling_max_count"]
  node_labels           = each.value["node_labels"]
  node_taints           = var.node_taints
  tags                  = module.tf_tagging.tags
  mode                  = each.value["mode"]
  ultra_ssd_enabled     = var.ultra_ssd_enabled

  timeouts {
    create = "120m"
    update = "120m"
    delete = "120m"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}

resource "vault_generic_secret" "kube_config" {
  path = var.vault_secret_path
  data_json = jsonencode({
    cluster_name          = "${azurerm_kubernetes_cluster.aks_cluster.name}"
    fqdn                  = "${azurerm_kubernetes_cluster.aks_cluster.fqdn}"
    kube_config_raw       = "${azurerm_kubernetes_cluster.aks_cluster.kube_config_raw}"
    private_fqdn          = "${azurerm_kubernetes_cluster.aks_cluster.private_fqdn}"
    kube_admin_config_raw = "${azurerm_kubernetes_cluster.aks_cluster.kube_admin_config_raw}"
  })
}

data "azurerm_monitor_diagnostic_categories" "aks" {
  resource_id = azurerm_kubernetes_cluster.aks_cluster.id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "all_diag"
  target_resource_id         = azurerm_kubernetes_cluster.aks_cluster.id
  log_analytics_workspace_id = var.workspace_id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.aks.log_category_types
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.aks.metrics
    content {
      category = metric.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }
}
