output "jenkins_public_ip" {
    description = "Public IP address of the Jenkins VM"
    value       = azurerm_public_ip.jenkins_pip.ip_address
}

output "app_service_url" {
    description = "URL of the deployed Flask app"
    value       = azurerm_linux_web_app.app.default_hostname
}

output "acr_login_server" {
    description = "Login server URL for the Azure Container Registry"
    value       = azurerm_container_registry.acr.login_server
}

output "postgres_fqdn" {
    description = "Fully qualified domain name of the PostgreSQL server"
    value       = azurerm_postgresql_flexible_server.postgresql.fqdn
}