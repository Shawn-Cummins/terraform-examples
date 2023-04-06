# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------

output "name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}

output "private_fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.private_fqdn
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.resource_group_name
}

output "location" {
  value = azurerm_kubernetes_cluster.aks_cluster.location
}

output "tags" {
  value = var.tags
}
