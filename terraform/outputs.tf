# ============================================================
# outputs.tf — values printed after terraform apply
#
# WHY outputs?
# After Terraform creates resources, you need certain values:
#   - ACR URL → to push Docker images
#   - App URL  → to test your deployed app
# Instead of searching in Azure Portal, Terraform prints them here.
# ============================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "ACR URL — add this as AZURE_ACR_LOGIN_SERVER secret in GitHub"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "ACR username — needed to push Docker images"
  value       = azurerm_container_registry.main.admin_username
}

output "acr_admin_password" {
  description = "ACR password — add as secret in GitHub"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true  # marked sensitive so Terraform won't print it in logs
}

output "dev_app_url" {
  description = "Your live app URL on Azure — open this in browser to test!"
  value       = "https://${azurerm_container_app.dev.ingress[0].fqdn}"
}
