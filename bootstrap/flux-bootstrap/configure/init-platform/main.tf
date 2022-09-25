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


resource "github_repository_file" "argo_workload_startmeup" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/workloads/argo-cd/startmeup/startmeup.yaml")
  content             = file("${path.module}/../platform-files/workloads/argo-cd/startmeup/startmeup.yaml")
}
