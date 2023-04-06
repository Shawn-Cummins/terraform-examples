
terraform {
  required_version = ">=0.15.1"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 1.4"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~>2.20"
    }
  }
}

provider "azurerm" {
  # subscription_id = local.per_environment_settings[var.environment].subscription_id
  features {

  }
}

provider "vault" {
  # The address of the vault in which to store deployed secrets
  address = "https://vault.url.com"
  # Defaults to 20 minutes. Increasing to 1 hour.
  max_lease_ttl_seconds = 3600
}
module "azure_aks" {
  source  = "git@github.com:Shawn-Cummins/terraform-examples.git"
  additional_node_pools = {}
  location = "eastus"
  environment = "np"
  workload_name = "testing"
  resource_group_name = "rg-aks-np"
  aks_cluster_admins_ad_group = ["ad_group"]
  subnet_id = "/subscriptions/subid/resourceGroups/rg-aks-np/providers/Microsoft.Network/virtualNetworks/vnet-aks-np/subnets/snet-aks-np"
  vault_secret_path = "secrets/path/to/secrets"
  tags = {
    "CostCenter" = "1234"
    "Owner" = "user.name@gmail.com"
  }
}