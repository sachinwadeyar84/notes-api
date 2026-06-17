# ============================================================
# variables.tf — all input values in one place
#
# WHY variables?
# Instead of hardcoding values like subscription IDs everywhere,
# we define them once here. If a value changes, update it here only.
# Also — sensitive values like IDs are passed in, not hardcoded.
# ============================================================

variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
  # Value comes from terraform.tfvars file (which we don't commit to Git)
}

variable "location" {
  description = "Azure region where all resources will be created"
  type        = string
  default     = "eastus"
  # WHY eastus? It's the cheapest and has most services available
}

variable "app_name" {
  description = "Name of the application — used to name all resources"
  type        = string
  default     = "notes-api"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
  default     = "dev"
}
