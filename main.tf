provider "azurerm" {
  features {}
  subscription_id = var.subscription
}

resource "azurerm_resource_group" "agent" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "agent" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.agent.name
  virtual_network_name = azurerm_virtual_network.agent.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.agent.name
  location            = azurerm_resource_group.agent.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "agent" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.agent.name
  location            = azurerm_resource_group.agent.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_security_group" "agent" {
  name                = "agent"
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ssh"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = azurerm_network_interface.agent.private_ip_address
  }
}

resource "azurerm_network_interface_security_group_association" "agent" {
  network_interface_id      = azurerm_network_interface.agent.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

resource "azurerm_linux_virtual_machine" "agent" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.agent.name
  location            = azurerm_resource_group.agent.location
  size                = "Standard_A1_v2"
  admin_username      = var.user
  network_interface_ids = [
    azurerm_network_interface.agent.id,
  ]

  admin_ssh_key {
    username   = var.user
    public_key = file("./ssh-keys/terraform-azure.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  custom_data = base64encode(templatefile("init.sh", {
    PAT  = var.pat
    USER = var.user
    POOL = var.pool
    ORG  = var.org
  }))
}