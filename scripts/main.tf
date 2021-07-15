provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "varpoc" {
 name     = "PocResourceGroup"
 location = "East Asia"
}

resource "azurerm_virtual_network" "varpoc" {
 name                = "webservervn"
 address_space       = ["10.0.0.0/16"]
 location            = azurerm_resource_group.varpoc.location
 resource_group_name = azurerm_resource_group.varpoc.name
}

resource "azurerm_subnet" "varpoc" {
 name                 = "webserversub"
 resource_group_name  = azurerm_resource_group.varpoc.name
 virtual_network_name = azurerm_virtual_network.varpoc.name
 address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "varpoc" {
 name                         = "publicIPForLB"
 location                     = azurerm_resource_group.varpoc.location
 resource_group_name          = azurerm_resource_group.varpoc.name
 allocation_method            = "Static"
}

resource "azurerm_lb" "varpoc" {
 name                = "loadBalancer"
 location            = azurerm_resource_group.varpoc.location
 resource_group_name = azurerm_resource_group.varpoc.name

 frontend_ip_configuration {
   name                 = "publicIPAddress"
   public_ip_address_id = azurerm_public_ip.varpoc.id
 }
}

resource "azurerm_lb_backend_address_pool" "varpoc" {
 resource_group_name = azurerm_resource_group.varpoc.name
 loadbalancer_id     = azurerm_lb.varpoc.id
 name                = "BackEndAddressPool"
}

resource "azurerm_network_interface" "varpoc" {
 count               = 2
 name                = "webserverni${count.index}"
 location            = azurerm_resource_group.varpoc.location
 resource_group_name = azurerm_resource_group.varpoc.name

 ip_configuration {
   name                          = "varpocConfiguration"
   subnet_id                     = azurerm_subnet.varpoc.id
   private_ip_address_allocation = "dynamic"
 }
}

resource "azurerm_managed_disk" "varpoc" {
 count                = 2
 name                 = "datadisk_existing_${count.index}"
 location             = azurerm_resource_group.varpoc.location
 resource_group_name  = azurerm_resource_group.varpoc.name
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "1023"
}

resource "azurerm_availability_set" "avset" {
 name                         = "avset"
 location                     = azurerm_resource_group.varpoc.location
 resource_group_name          = azurerm_resource_group.varpoc.name
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

resource "azurerm_virtual_machine" "varpoc" {
 count                 = 2
 name                  = "webservervm${count.index}"
 location              = azurerm_resource_group.varpoc.location
 availability_set_id   = azurerm_availability_set.avset.id
 resource_group_name   = azurerm_resource_group.varpoc.name
 network_interface_ids = [element(azurerm_network_interface.varpoc.*.id, count.index)]
 vm_size               = "Standard_DS1_v2"

 
 storage_image_reference {
   publisher = "MicrosoftWindowsServer"
   offer     = "WindowsServer"
   sku       = "2019-Datacenter"
   version   = "latest"
 }

 storage_os_disk {
   name              = "myosdisk${count.index}"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 # data disks
 storage_data_disk {
   name              = "datadisk_new_${count.index}"
   managed_disk_type = "Standard_LRS"
   create_option     = "Empty"
   lun               = 0
   disk_size_gb      = "1023"
 }

 storage_data_disk {
   name            = element(azurerm_managed_disk.varpoc.*.name, count.index)
   managed_disk_id = element(azurerm_managed_disk.varpoc.*.id, count.index)
   create_option   = "Attach"
   lun             = 1
   disk_size_gb    = element(azurerm_managed_disk.varpoc.*.disk_size_gb, count.index)
 }

 os_profile {
   computer_name  = "hostname"
   admin_username = "azuser"
   admin_password = "Shriram@@11"
 }

 os_profile_windows_config {
  
 }

}