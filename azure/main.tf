################################################################################
# terraform dependencies

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.25.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }
  }

  backend "azurerm" {
    resource_group_name  = "dump-cloud-snowflakes"
    storage_account_name = "tfstate2022"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_version = ">= 1.2.0"
}

provider "azurerm" {
  features {}
}

provider "random" {}

################################################################################
# resource group

resource "azurerm_resource_group" "rg" {
  name     = "dump-cloud"
  location = "germanywestcentral"
}

################################################################################
# net

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "netsg" {
  name                = "netsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.cloud_ip_id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_netsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.netsg.id
}

################################################################################
# vm

resource "random_password" "vm_password" {
  length = 40
  lower  = true
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2s"
  admin_username                  = "dump-deploy"
  admin_password                  = random_password.vm_password.result
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic.id]
  source_image_id                 = var.vm_image_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }
}