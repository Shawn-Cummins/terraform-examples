output "primary_blob_endpoint" {
  description = "Public endpoint of blob storage"
  value       = azurerm_storage_account.stg.primary_blob_endpoint
}

output "id" {
  description = "ID of Storage Account"
  value       = azurerm_storage_account.stg.id
}

output "primary_location" {
  description = "Primary Location of Storage Account"
  value       = azurerm_storage_account.stg.primary_location
}

output "name" {
  description = "Name of Storage Account"
  value       = azurerm_storage_account.stg.name
}

output "primary_connection_string" {
  description = "The connection string associated with the primary location"
  value       = azurerm_storage_account.stg.primary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.stg.primary_access_key
  sensitive   = true
}
