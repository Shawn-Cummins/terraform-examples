# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Dictionary of tags to associate to the resource. Example: tags = {\"Owner\" = \"your-team-distro@dcsg.com\" \"CostCenter\"  = 12345}."
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Specifies the Resource Group where the Managed Kubernetes Cluster should exist. Changing this forces a new resource to be created."
  type        = string
}

variable "subnet_id" {
  description = "The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "The location where the Managed Kubernetes Cluster should be created. Changing this forces a new resource to be created."
  type        = string
}

variable "zones" {
  description = "Specifies a list of Availability Zones in which this Kubernetes Cluster should be located. Changing this forces a new Kubernetes Cluster to be created."
  type        = list(string)
  default     = null
}

# The name can contain only letters, numbers, underscores and hyphens. The name must start and end with letter or number.
# Kubernetes service name must be unique in the current resource group.
variable "workload_name" {
  description = "The workload name of the aks cluster"
  type        = string

  validation {
    condition     = !can(regex("^aks-", var.workload_name))
    error_message = "The workload_name value must not include aks-, this will be added to the prefix automatically in the module."
  }
}

variable "kubernetes_version" {
  description = "Version of Kubernetes specified when creating the AKS managed cluster. If not specified, the latest recommended version will be used at provisioning time (but won't auto-upgrade)."
  type        = string
  default     = null
}

variable "node_name" {
  description = "The name which should be used for the default Kubernetes Node Pool. Changing this forces a new resource to be created."
  type        = string
  default     = "default"
}

variable "node_vm_size" {
  description = "The size of the Virtual Machine, such as Standard_DS2_v2. Changing this forces a new resource to be created."
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  type        = number
  default     = 50
}

variable "node_count" {
  description = "The initial number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000 and between min_count and max_count."
  type        = number
  default     = 1
}

variable "max_pods" {
  description = "The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 100
}

variable "environment" {
  description = "Environment: sbx, np, qa, or p"
  type        = string
}

variable "enable_auto_scaling" {
  description = "Should the Kubernetes Auto Scaler be enabled for this Node Pool? Defaults to false."
  type        = bool
  default     = true
}

variable "auto_scaling_min_count" {
  description = "The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000."
  type        = number
  default     = 1
}

variable "auto_scaling_max_count" {
  description = "The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 1000."
  type        = number
  default     = 3
}

variable "additional_node_pools" {
  description = "Node pools in addition to the default one."
  type = map(object({
    zones                  = list(string)
    vm_size                = string
    os_disk_size_gb        = number
    node_count             = number
    enable_auto_scaling    = bool
    auto_scaling_min_count = number
    auto_scaling_max_count = number
    node_labels            = map(string)
    mode                   = string
    ultra_ssd_enabled      = bool
  }))
}

variable "vault_secret_path" {
  description = "The full logical path from which to request data. (i.e. secrets/path/to/secret)"
  type        = string
}

variable "node_labels" {
  description = "A map of Kubernetes labels which should be applied to nodes in the Default Node Pool."
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "A list of Kubernetes taints which should be applied to nodes in the agent pool (e.g key=value:NoSchedule). Changing this forces a new resource to be created."
  type        = list(string)
  default     = []
}

variable "app_insights_workspace_id" {
  description = "Specifies the ID of the Log Analytics Workspace where the audit logs collected by Microsoft Defender should be sent to."
  type        = string
  default     = null
}

variable "ultra_ssd_enabled" {
  description = "Used to specify whether the UltraSSD is enabled in the Default Node Pool. Defaults to false."
  type        = bool
  default     = false
}

variable "aks_cluster_admins_ad_group" {
  description = "AD Group for cluster administrators"
  type        = list(any)
}

variable "oidc_issuer_enabled" {
  description = "Used to specify whether the OIDC feature is enabled. Defaults to false."
  type        = bool
  default     = false
}