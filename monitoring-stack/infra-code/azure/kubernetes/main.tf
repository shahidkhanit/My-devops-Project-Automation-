terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${var.environment}"
  location = var.location
}

# AKS Cluster for DevOps
resource "azurerm_kubernetes_cluster" "devops_cluster" {
  name                = "aks-devops-cluster"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  dns_prefix          = "devops-cluster"

  default_node_pool {
    name       = "devops"
    node_count = 3
    vm_size    = "Standard_D2_v2"
    
    tags = {
      cluster = "devops"
      role    = "monitoring"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Purpose     = "monitoring"
  }
}

# AKS Cluster for Applications
resource "azurerm_kubernetes_cluster" "application_cluster" {
  name                = "aks-application-cluster"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  dns_prefix          = "application-cluster"

  default_node_pool {
    name       = "apps"
    node_count = 5
    vm_size    = "Standard_D4_v2"
    
    tags = {
      cluster = "application"
      role    = "workload"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Purpose     = "applications"
  }
}