provider "azurerm"{
    version = "2.2.0"
    features {}
}

resource "azurerm_resource_group" "web_server_rg"{
    name = var.web_server_rg
    location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet"{
    name = "${var.resource_prefix}-vnet"
    location = var.web_server_location
    resource_group_name=azurerm_resource_group.web_server_rg.name
    address_space=[var.web_server_address_space]

}
resource "azurerm_subnet" "web_server_subnet"{
    name = "${var.resource_prefix}-subnet"
    resource_group_name=azurerm_resource_group.web_server_rg.name
    virtual_network_name=azurerm_virtual_network.web_server_vnet.name
    address_prefix=var.web_server_address_prefix
}
resource "azurerm_network_interface" "web_server_nic"{
name = "${var.web_server_name}-nic"
location = var.web_server_location
resource_group_name=azurerm_resource_group.web_server_rg.name

ip_configuration{
name="${var.web_server_name}-ip"
subnet_id=azurerm_subnet.web_server_subnet.id
private_ip_address_allocation="dynamic"
## added for Virtual Machine 
public_ip_address_id=azurerm_public_ip.web_server_public_ip.id
}
}
resource "azurerm_public_ip" "web_server_public_ip"{
    name = "${var.resource_prefix}-public_ip"
    location = var.web_server_location
    resource_group_name=azurerm_resource_group.web_server_rg.name
    allocation_method="Dynamic"

}

resource "azurerm_network_security_group" "web_server_nsg"{
    name="${var.resource_prefix}-nsg"
    location=var.web_server_location
    resource_group_name=azurerm_resource_group.web_server_rg.name
}
resource "azurerm_network_security_rule" "web_server_nsg_rule"{
    name="RDP Inbound"
    priority=100
    direction="Inbound"
    access="Allow"
    protocol="Tcp"
    source_port_range="*"
    destination_port_range="3389"
    source_address_prefix="*"
    destination_address_prefix="*"
    resource_group_name=azurerm_resource_group.web_server_rg.name
    network_security_group_name=azurerm_network_security_group.web_server_nsg.name
}   

resource "azurerm_network_interface_security_group_association" "web_server_nsg_association"{
    network_security_group_id=azurerm_network_security_group.web_server_nsg.id
    network_interface_id=azurerm_network_interface.web_server_nic.id
}
resource "azurerm_windows_virtual_machine" "web_server"{
    name=var.web_server_name
    location=var.web_server_location
    resource_group_name=azurerm_resource_group.web_server_rg.name
    network_interface_ids=[azurerm_network_interface.web_server_nic.id]
    availability_set_id=azurerm_availability_set.Web_server_availability_set.id
    size="Standard_B1s"
    admin_username="webserver"
    admin_password="P@ssw0rd1234"

    os_disk{
        caching="ReadWrite"
        storage_account_type="Standard_LRS"
    }

    source_image_reference{
        publisher  ="MicrosoftWindowsServer"
        offer      ="WindowsServer"
        sku        ="2016-Datacenter"
        version    ="latest"
    }
}

resource "azurerm_availability_set" "Web_server_availability_set"{
    name ="${var.resource_prefix}-availabilitySet"
    location=var.web_server_location
    resource_group_name=azurerm_resource_group.web_server_rg.name
    managed=true 
    platform_fault_domain_count=2

}
