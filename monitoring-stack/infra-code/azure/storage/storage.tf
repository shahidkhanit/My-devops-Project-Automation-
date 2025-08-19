resource "azurerm_storage_account" "monitoring_storage" {
  name                     = "stmonitoring${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.monitoring.name
  location                 = azurerm_resource_group.monitoring.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Purpose     = "monitoring"
  }
}

resource "azurerm_storage_container" "mimir_container" {
  name                  = "mimir-metrics"
  storage_account_name  = azurerm_storage_account.monitoring_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "loki_container" {
  name                  = "loki-logs"
  storage_account_name  = azurerm_storage_account.monitoring_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tempo_container" {
  name                  = "tempo-traces"
  storage_account_name  = azurerm_storage_account.monitoring_storage.name
  container_access_type = "private"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}