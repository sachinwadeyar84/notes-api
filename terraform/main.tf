# ============================================================
# main.tf — all Azure resources for the Notes API
#
# RESOURCES WE CREATE:
# 1. Resource Group     — folder that holds everything
# 2. Container Registry — stores our Docker image
# 3. Container App Env  — the platform that runs containers
# 4. Container App      — our actual running application
# ============================================================


# ============================================================
# RESOURCE 1: Resource Group
#
# WHY: In Azure, every resource MUST belong to a Resource Group.
# Think of it as a folder.
# If you delete the Resource Group → everything inside is deleted too.
# This makes cleanup very easy — one delete command removes everything.
# ============================================================
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}"
  location = var.location

  tags = {
    # Tags help you track costs and find resources easily
    # In organisations, every resource must have these tags
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"   # so everyone knows this was created by Terraform
  }
}


# ============================================================
# RESOURCE 2: Azure Container Registry (ACR)
#
# WHY: This is like a private Docker Hub, but inside YOUR Azure account.
# Your Docker images are stored here securely.
# Only your Azure resources (Container Apps, AKS) can pull from it.
# Nobody else can access your images.
# ============================================================
resource "azurerm_container_registry" "main" {
  # ACR name must be globally unique across ALL of Azure
  # No hyphens allowed — only letters and numbers
  name                = "acr${replace(var.app_name, "-", "")}sachin001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Basic = cheapest tier, good for learning
  # Standard = for production (better performance, more storage)
  # Premium = for enterprises (geo-replication, private endpoints)
  sku = "Basic"

  # Allow pulling images without a password using Managed Identity
  # WHY: No passwords = no password to steal or rotate
  admin_enabled = true

  tags = azurerm_resource_group.main.tags
}


# ============================================================
# RESOURCE 3: Container Apps Environment
#
# WHY: Container Apps need an "environment" to run in.
# Think of it as the building — Container Apps are offices inside.
# The environment handles networking, logging, and scaling for all apps inside it.
# One environment can host MULTIPLE apps (dev app, prod app, etc.)
# ============================================================
resource "azurerm_log_analytics_workspace" "main" {
  # Container Apps sends logs here automatically
  # WHY Log Analytics? So you can search logs, create alerts,
  # and see what your app is doing in production
  name                = "law-${var.app_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"  # pay per GB of logs — cheapest option
  retention_in_days   = 30           # keep logs for 30 days, then auto-delete

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.app_name}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location

  # Connect the environment to Log Analytics so all app logs go there
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = azurerm_resource_group.main.tags
}


# ============================================================
# RESOURCE 4: Container App — DEV
#
# WHY Container Apps and not a VM?
# VM = you manage the OS, patching, scaling, availability
# Container Apps = Azure manages everything, you just give it a container
# You only pay when your app is actually running (scales to zero at night)
#
# For our learning project, a VM would cost money 24/7.
# Container Apps = FREE when not in use (scales to zero).
# ============================================================
resource "azurerm_container_app" "dev" {
  name                         = "${var.app_name}-dev"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name

  # Revision mode = how updates work
  # Single = one version running at a time (simpler, good for learning)
  # Multiple = run old and new version together (blue/green deployment)
  revision_mode = "Single"

  # Connect to our ACR so it can pull the Docker image
  registry {
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.admin_username
    password_secret_name = "acr-password"
  }

  # Secrets stored securely in Container Apps (not in your code)
  secret {
    name  = "acr-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    container {
      name   = var.app_name
      # Use latest image from our ACR — pipeline will update this
      image  = "${azurerm_container_registry.main.login_server}/${var.app_name}:latest"

      # Resource limits — how much CPU and memory this app can use
      # 0.25 CPU and 0.5Gi memory = smallest size (cheapest, good for our API)
      cpu    = 0.25
      memory = "0.5Gi"

      # Environment variable passed into the container
      env {
        name  = "PORT"
        value = "5000"
      }
    }

    # Scale to zero when no traffic — saves money!
    # Min 0 = no replicas running when nobody is using the app
    # Max 1 = spin up 1 replica when a request comes in
    min_replicas = 0
    max_replicas = 1
  }

  # Ingress = how traffic reaches your app from the internet
  ingress {
    external_enabled = true    # accessible from the internet
    target_port      = 5000    # must match the PORT in your Flask app

    traffic_weight {
      percentage      = 100    # send 100% of traffic to this revision
      latest_revision = true
    }
  }
}
