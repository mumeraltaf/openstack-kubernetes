terraform {
  required_version = ">= 1.3.0"

  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}


resource "github_repository_file" "cluster_issuer_lets_encrypt" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/cert-manager/lets-encrypt-issuer.yaml")
  content             = file("${path.module}/../platform-files/platform/cert-manager/lets-encrypt-issuer.yaml")
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

resource "github_repository_file" "github_runner" {
  depends_on = [ kubernetes_secret_v1.container-repository-secret]
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/workloads/github-runners/startmeup-runner.yaml")
  content             = file("${path.module}/../platform-files/workloads/github-runners/startmeup-runner.yaml")
}

resource "github_repository_file" "argo_workload_startmeup" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/workloads/argo-cd/startmeup/startmeup.yaml")
  content             = file("${path.module}/../platform-files/workloads/argo-cd/startmeup/startmeup.yaml")
}
