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

# 1. Core Resource Group Configuration
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# 2. Production Virtual Network Topology
resource "azurerm_virtual_network" "vnet" {
  name                = "Prod-Core-VNet"
  address_space       = var.vnet_cidr
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Network Segmentation - Public Frontend Web Tier
resource "azurerm_subnet" "web_subnet" {
  name                 = "Web-Tier-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.web_subnet_cidr
}

# 4. Network Segmentation - Private Isolated Backend Application Tier
resource "azurerm_subnet" "app_subnet" {
  name                 = "App-Tier-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_subnet_cidr
}

# 5. Security Perimeter - Web Tier NSG (Permits Inbound Web Traffic Only)
resource "azurerm_network_security_group" "web_nsg" {
  name                = "Web-Tier-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 6. Security Perimeter - App Tier NSG (Zero Trust Model: Allows Traffic From Web Subnet Only)
resource "azurerm_network_security_group" "app_nsg" {
  name                = "App-Tier-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Traffic-From-Web-Only"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.web_subnet_cidr[0] # Restricts source to Web Subnet addresses dynamically
    destination_address_prefix = var.app_subnet_cidr[0]
  }
}

# 7. High Availability Component - Public Load Balancer Front Infrastructure
resource "azurerm_public_ip" "lb_pip" {
  name                = "LoadBalancer-PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "web_lb" {
  name                = "Enterprise-Web-LoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}