# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "ContactsRg"
  location = "West Europe"
}

resource "azurerm_service_plan" "asp" {
  name                = "ContactsServicePlan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "alwa" {
  name                = "ContactsApp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_server.sqlserver.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False;MultipleActiveResultSets=True;"
  }


  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
}


resource "azurerm_mssql_server" "sqlserver" {
  name                         = "mssqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "myStrongPassword12#"
  minimum_tls_version          = "1.2"
}


resource "azurerm_mssql_database" "database" {
  name           = "acctest-db-d"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "afr" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_app_service_source_control" "scv" {
  app_id                = azurerm_linux_web_app.alwa.id
  repo_url               = "https://github.com/konstantin-milchev/Contacts.git"
  branch                 = "main"
  use_manual_integration = true
}