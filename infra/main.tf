# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg
  location = var.location
}

# Virtual Network & Subnets

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.rg}-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
    name = "private-endpoints-subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["192.168.2.0/24"]
  }

resource "azurerm_subnet" "jenkins_subnet" {
    name = "jenkins-subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["192.168.3.0/24"]
}

# ACR

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

# PostgreSQL Flexible Server

resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                = var.postgres_server_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  version             = "15"
  administrator_login = var.sql_username
  administrator_password = var.sql_password

  storage_mb = 32768
  storage_tier = "P4"
  sku_name = "B_Standard_B1ms"

  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_link]
}

# Create a database in the PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server_database" "db" {
    name = var.db_name
    server_id = azurerm_postgresql_flexible_server.postgresql.id
    charset = "UTF8" 
}

# Private Endpoint for PostgreSQL and Private DNS Zone
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_endpoint" "postgres_pe" {
  name                = "psql-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "postgres-privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.postgresql.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "postgres-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgres_dns.id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "postgres-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# keyvault

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.rg}-kv"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = var.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  lifecycle {
    prevent_destroy = false
    ignore_changes  = []
  }
}

# Create a secret in Key Vault for the database connection string
resource "azurerm_key_vault_secret" "db_url" {
    name = "databaseurl"
    value = "postgresql+psycopg2://${var.sql_username}:${var.sql_password}@${azurerm_postgresql_flexible_server.postgresql.fqdn}:5432/${var.db_name}"
    key_vault_id = azurerm_key_vault.kv.id

    depends_on = [ azurerm_key_vault.kv ]
}

# App Services

resource "azurerm_service_plan" "app_service_plan" {
    name = "flask-app-plan"
    resource_group_name = azurerm_resource_group.rg.name
    location = var.location
    os_type = "Linux"
    sku_name = "B2"
}

resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name   = "${var.acr_name}.azurecr.io/flask-app:latest"
      docker_registry_url = "https://${var.acr_name}.azurecr.io"
    }
  }

  app_settings = {
    FLASK_ENV    = "production"
    databaseurl = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_url.id})"
  }
}

# VNet integration for App Service
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = azurerm_subnet.app_subnet.id
}

# Grant App Service managed identity access to ACR
resource "azurerm_role_assignment" "app_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# Grant App Service managed identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app_kv_policy" {
    depends_on = [azurerm_linux_web_app.app, azurerm_key_vault.kv]
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

# Grant current user/service principal access to manage secrets in Key Vault
resource "azurerm_key_vault_access_policy" "current_user_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "Delete", "List"]
}

# Jenkins VM
resource "azurerm_network_interface" "jenkins_nic" {
  name                = "jenkins-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "jenkins-ip-config"
    subnet_id                     = azurerm_subnet.jenkins_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_pip.id
  }
}

resource "azurerm_public_ip" "jenkins_pip" {
  name                = "jenkins-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "jenkins-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.your_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Jenkins"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.your_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.jenkins_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    #wait for system to initialize
    wait 60
    
    sudo apt update

    # Install Java and Jenkins
    sudo apt install -y fontconfig openjdk-21-jre
    
    wait 30
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt update
    
    # wait for update to complete
    wait 30
    
    sudo apt install -y jenkins
    
    # wait for jenkins to finish installing
    wait 30

    # Install Docker
    curl -fsSL https://get.docker.com | sudo sh

    sudo usermod -aG docker jenkins
    
    # wait for docker to finish installing
    wait 60

    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    # wait for Azure CLI to finish installing
    wait 60

    # enable and start Jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    
  EOF
  )
}
