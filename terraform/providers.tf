# ============================================================
# providers.tf — tells Terraform WHICH cloud we are using
#
# Provider = a plugin that lets Terraform talk to a cloud
# azurerm  = Azure Resource Manager (creates Azure resources)
# ============================================================

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110.0"  # pin version so it doesn't auto-upgrade and break things
    }
  }
}

# Configure the Azure provider
# Terraform reads your Azure login from az login automatically
provider "azurerm" {
  features {}

  # These come from environment variables or az login
  subscription_id = var.subscription_id
}
