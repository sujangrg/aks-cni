variable "prefix" {
  type    = string
  default = "sgu-aks"
}


# Resource group to hold Azure resources
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = "australiasoutheast"
}

resource "azurerm_virtual_network" "engagement" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["16.0.0.0/8"]
}

resource "azurerm_subnet" "kubesubnet" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.engagement.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = "16.0.0.0/22"
}


resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "sgu-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name                = "nodepool"
    node_count          = 1
    vm_size             = "Standard_D2_v2"
    type                = "VirtualMachineScaleSets"
    max_pods            = 110
    os_disk_size_gb     = 128
    vnet_subnet_id      = azurerm_subnet.redis.id
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    dns_service_ip     = "10.1.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.1.0.0/16"
  }


  service_principal {
    client_id = "2e14b0b0-ccad-4761-9fea-f553e2cc41e2"
    client_secret = ""
  }

  depends_on = [azurerm_virtual_network.engagement]

}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.k8s.kube_config_raw
}
