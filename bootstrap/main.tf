terraform {
  required_version = ">= 1.3.0"

  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
    github = {
      source  = "integrations/github"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
    flux = {
      source  = "fluxcd/flux"
    }
    tls = {
      source  = "hashicorp/tls"
    }

  }
}


provider "kubernetes" {
  config_path = "/Users/maalt/work/playpen/openstack-kubernetes/cluster/rke2.yaml"
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

module "flux-bootstrap" {
  source = "./flux-bootstrap"
  github_owner = var.github_owner
  github_token = var.github_token
}

resource "time_sleep" "wait_for_flux_bootstrap_first_sync" {
  depends_on = [module.flux-bootstrap]
  create_duration = "1m"
}

module "configure" {
  depends_on = [time_sleep.wait_for_flux_bootstrap_first_sync]
  source = "./flux-bootstrap/configure"
  github_owner = var.github_owner
  github_token = var.github_token
  github_app_id = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_private_key_path = var.github_app_private_key_path
  container_registry = var.container_registry
  registry_password = var.registry_password
  registry_username = var.registry_username
}

resource "time_sleep" "wait_for_configure" {
  depends_on = [module.configure]
  create_duration = "2m"
}

module "init_platform" {
  depends_on = [time_sleep.wait_for_configure]
  source = "./flux-bootstrap/configure/init-platform"
  github_owner = var.github_owner
  github_token = var.github_token
  github_app_id = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_private_key_path = var.github_app_private_key_path
  container_registry = var.container_registry
  registry_password = var.registry_password
  registry_username = var.registry_username
}

resource "time_sleep" "wait_for_init_platform" {
  depends_on = [module.init_platform]
  create_duration = "2m"
}

module "init_platform-2" {
  depends_on = [time_sleep.wait_for_init_platform]
  source = "./flux-bootstrap/configure/init-platform/init-platform-2"
  github_owner = var.github_owner
  github_token = var.github_token
  github_app_id = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_private_key_path = var.github_app_private_key_path
  container_registry = var.container_registry
  registry_password = var.registry_password
  registry_username = var.registry_username
}