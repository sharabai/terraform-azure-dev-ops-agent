terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = "~>1.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/${var.org}"
  personal_access_token = var.pat
}

resource "azurerm_resource_group" "agent" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "agent" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
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
  allocation_method   = "Static"

  lifecycle {
    create_before_destroy = true
  }
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
  size                = local.size
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

data "azuredevops_project" "example" {
  name = var.devops_project_name
}

resource "azuredevops_variable_group" "terraform_outputs" {
  project_id = data.azuredevops_project.example.id
  name = "Terraform Outputs"
  allow_access = true
  variable {
    name = "resourceGroup"
    value = azurerm_resource_group.agent.name
  }
  variable {
    name = "clusterName"
    value = var.aks_cluster_name
  }
  variable {
    name = "subscription"
    value = var.subscription
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name
  dns_prefix          = "example"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = local.node_size
    auto_scaling_enabled = true
    max_count = var.profile == "dev" ? 1 : var.node_max_count
    min_count = var.profile == "dev" ? 1 : var.node_min_count
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.profile
  }

  lifecycle {
    ignore_changes = [ default_node_pool ]
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.example.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.example.kube_config_raw
  sensitive = true
}

resource "azurerm_kubernetes_cluster_node_pool" "prod" {
  count = var.profile == "prod" ? 1 : 0

  name                  = "internal"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  vm_size               = "Standard_DS2_v2"
  auto_scaling_enabled = true
  min_count = var.node_min_count
  max_count = var.node_max_count

  tags = {
    Environment = var.profile
  }
}