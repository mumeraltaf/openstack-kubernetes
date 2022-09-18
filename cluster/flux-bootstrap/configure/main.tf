# Setup all required providers
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
  }

}
provider "kubernetes" {
  config_path = var.kube_config
}

# Create github app secret
resource "kubernetes_secret_v1" "actions-runner-controller-manager-secret" {
  metadata {
    name = "controller-manager"
    namespace = "actions-runner-system"
  }
  data = {
    "github_app_id" = var.github_app_id
    "github_app_installation_id" = var.github_app_installation_id
    "github_app_private_key" = file(var.github_app_private_key_path)
  }

}

# Create self-hosted-runners namespace
resource "kubernetes_namespace" "self-hosted-runners-namespace" {
  metadata {
    name = "self-hosted-runners"
  }
}

# Create self-hosted-runners secret
resource "kubernetes_secret_v1" "container-repository-secret" {
  depends_on = [kubernetes_namespace.self-hosted-runners-namespace]
  metadata {
    name = "container-repository"
    namespace = "self-hosted-runners"
  }
  data = {
    "REGISTRY_USERNAME" = var.registry_username
    "REGISTRY_PASSWORD" = var.registry_password
    "REGISTRY" = var.container_registry
  }

}
