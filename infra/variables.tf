variable "rg" {
    description = "Name of the resource group"
    type        = string
  
}

variable "location" {
    description = "Azure region for the resources"
    type        = string
}

variable "acr_name"{
    description = "Name of the Azure Container Registry"
    type        = string
}

variable "postgres_server_name" {
    description = "Name of the PostgreSQL server"
    type        = string
}

variable "sql_username" {
    description = "Username for PostgreSQL server"
    type        = string
}

variable "sql_password" {
    description = "Password for PostgreSQL server"
    type        = string
    sensitive   = true
}

variable "db_name" {
    description = "Name of the PostgreSQL database"
    type        = string
}

variable "app_name" {
    description = "Name of the App Service"
    type        = string
}

variable "your_ip" {
    description = "Your current IP address for firewall rules"
    type        = string
}

variable "ssh_public_key_path" {
    description = "Path to the SSH public key for the Jenkins VM"
    type        = string
    default = "~/.ssh/id_rsa.pub"
}