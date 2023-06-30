provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "rgvnet" {
  name                = "demo-vnet"
  location            = "centralindia"
  resource_group_name = "nishan"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "rgsubnet" {
  name                 = "demo-subnet"
  resource_group_name  = "nishan"
  virtual_network_name = azurerm_virtual_network.rgvnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_public_ip" "rgpub" {
  name                = "demo-pubip"
  resource_group_name = "nishan"
  location            = "centralindia"
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "rgnsg" {
  name                = "demo-nsg"
  location            = "centralindia"
  resource_group_name = "nishan"

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

resource "azurerm_network_interface" "rgnic" {
  name                      = "demo-nic"
  location                  = "centralindia"
  resource_group_name       = "nishan"

  ip_configuration {
    name                          = "demo-ipconfig"
    subnet_id                     = azurerm_subnet.rgsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.5"  # Provide a specific private IP address here
    public_ip_address_id          = azurerm_public_ip.rgpub.id
  }
}

resource "azurerm_virtual_machine" "rgvirt" {
  name                  = "demo-vm"
  location              = "centralindia"
  resource_group_name   = "nishan"
  network_interface_ids = [azurerm_network_interface.rgnic.id]
  vm_size               = "Standard_DS2_V2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

 storage_os_disk {
  name              = "new-disk-name"
  create_option     = "FromImage"
  caching           = "ReadWrite"
  managed_disk_type = "Premium_LRS"
}



  os_profile {
    computer_name  = "myvm"
    admin_username = "nishan"
    admin_password = "udupi@123456"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    type        = "ssh"
    user        = "nishan"
    password    = "udupi@123456"
    host        = azurerm_public_ip.rgpub.ip_address
    port        = 22
    timeout     = "2m"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable'",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce",
      "sudo usermod -aG docker $USER"
    ]
  }
}