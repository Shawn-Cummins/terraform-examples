variable "workload_name" {
  description = "Used to name the storage account. Will be prefixed by 'st' and suffixed with the environment and region abbreviation. Only lowercase Alphanumeric characters allowed. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,13}$", replace(var.workload_name, "-", "")))
    error_message = "The workload_name must be between 3 and 13 characters in length, may contain numbers and lowercase letters only, and must be globally unique."
  }
  validation {
    condition     = !can(regex("^st", var.workload_name))
    error_message = "The workload_name should not start with st, this will be added to the prefix automatically in the module."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the storage account. Changing this forces a new resource to be created."
  type        = string
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool, defaults to Hot."
  type        = string
  default     = "Hot"
}

variable "account_kind" {
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Changing this forces a new resource to be created. Defaults to StorageV2."
  type        = string
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Changing this forces a new resource to be created when types LRS, GRS and RAGRS are changed to ZRS, GZRS or RAGZRS and vice versa."
  type        = string
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created."
  type        = string
}

variable "firewall_subnet_ids" {
  description = "List of subnet IDs to be added to the firewall VNET rules. Example: [\"/subscriptions/SUBSCRIPTION-ID/resourceGroups/RG-NAME/providers/Microsoft.Network/virtualNetworks/VNET-NAME/subnets/SNET-NAME\"]"
  type        = list(string)
  default     = []
}

variable "ip_range_filter" {
  description = "List of public ip ranges to allow access."
  type        = list(string)
  default     = []
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created. Example: eastus"
  type        = string
}

variable "soft_delete_retention_days" {
  description = "Specifies the number of days that the blob and container should be retained, between 1 and 365 days. Defaults to 7."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Dictionary of tags to associate to the resource. Example: tags = {\"Owner\" = \"user.name@email.com\" \"CostCenter\"  = 12345}."
  type        = map(string)
}

variable "vault_secret_path" {
  description = "The path in the vault to store secrets (i.e. secrets/path/to/secret)"
  type        = string
}

variable "versioning_enabled" {
  description = "Is versioning enabled? Defaults to true unless using FileStorage."
  type        = bool
  default     = true
}

variable "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 (https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal). Changing this forces a new resource to be created. This can only be true when account_tier is Standard or when account_tier is Premium and account_kind is BlockBlobStorage. Defaults to false."
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Whether or not to enable NFSv3. To enable NFS v3 'hierarchical namespace' must be enabled."
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Is Large File Share Enabled? Provides file share support up to a maximum of 100 TiB. Large file share storage accounts do not have the ability to convert to geo-redundant storage offerings and upgrade is permanent. Defaults to false."
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "A list of CORS rule.   cors_rules = [{allowed_headers = [\"*\"] allowed_methods = [\"GET\", \"POST\"] allowed_origins = [\"https://example.com\"] exposed_headers = [\"*\"] max_age_in_seconds = 3600}]"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

variable "allow_nested_items_to_be_public" {
  description = "Allow or disallow nested items within this Account to opt into being public. Defaults to false."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new private endpoint resource to be created."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment: sbx, np, qa, or p"
  type        = string
}