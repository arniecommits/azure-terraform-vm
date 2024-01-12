data "azurerm_subscription" "primary" {}

resource "random_string" "random_str_val" {
  special = false
  length =8
  min_upper = 8
}

resource "random_string" "random_str_lower" {
  special = false
  upper = false
  length =8
}



# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${format("%s%s",var.resource_group_name,"-PUBIP")}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
   tags = {
      Owner = var.tags["value"]  
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${format("%s%s",var.resource_group_name,"-NSG")}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Open-ALL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "Open-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
      Owner = var.tags["value"]  
    }  

}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${format("%s%s",var.resource_group_name,"-NIC")}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = var.subnetid
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }

tags = {
        Owner = var.tags["value"]  
    }   

}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#cloud-init-script 
locals {
  custom_data = <<EOF
#!/bin/bash
sudo apt -y update && apt -y upgrade
sudo apt -y install php php-curl libapache2-mod-php apache2 composer imagemagick
sudo systemctl enable apache2
sudo mkdir -p /var/www/data
sudo rm -f /etc/ImageMagick-6/policy.xml
sudo rm -rf /var/www/html/*
sudo git clone https://github.com/dodgycoder/Azure-PDF-APP.git /var/www/html/
sudo chown -R www-data:www-data /var/www/
sudo systemctl start apache2
EOF
  }



# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "VM-${random_string.random_str_val.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B2s"

  os_disk {
    name                 = "Disk-${random_string.random_str_val.result}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "VM-${random_string.random_str_val.result}"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
    
  }
}