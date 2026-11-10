terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  default = "francecentral"
}

# A folder for everything in this project
resource "azurerm_resource_group" "rg" {
  name     = "rg-safehome-k8s"
  location = var.location
}

# The registry. Name must be globally unique, letters and numbers only.
resource "azurerm_container_registry" "acr" {
  name                = "safehomeacr${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
# The Kubernetes cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-safehome"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "safehome"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.logs.id
    msi_auth_for_monitoring_enabled = true
  }
}

# Let the cluster pull images from our registry (least privilege: pull only)
resource "azurerm_role_assignment" "aks_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
# Where logs and health data are stored
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-safehome"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Who gets told
variable "alert_email" {
  description = "Email address for alerts"
}

resource "azurerm_monitor_action_group" "oncall" {
  name                = "ag-safehome-oncall"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "safehome"

  email_receiver {
    name          = "me"
    email_address = var.alert_email
  }
}

# The check: fewer than 2 running safehome pods -> alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pods_down" {
  name                = "safehome-pods-below-2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  scopes              = [azurerm_log_analytics_workspace.logs.id]
  severity            = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query = <<-KQL
      KubePodInventory
      | where Namespace == "default" and Name startswith "safehome"
      | where PodStatus == "Running"
      | summarize arg_max(TimeGenerated, *) by Name
      | summarize RunningPods = count()
    KQL
    time_aggregation_method = "Maximum"
    metric_measure_column   = "RunningPods"
    operator                = "LessThan"
    threshold               = 2
  }

  action {
    action_groups = [azurerm_monitor_action_group.oncall.id]
  }
}
