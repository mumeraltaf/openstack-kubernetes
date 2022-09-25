terraform {
  required_version = ">= 1.3.0"

  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}




resource "github_repository_file" "arc_repo" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/actions-runner-controller/helmrepo-actions-runner-controller.yaml")
  content             = file("${path.module}/../../platform-files/platform/actions-runner-controller/helmrepo-actions-runner-controller.yaml")
}

resource "github_repository_file" "arc_release" {
  depends_on = [github_repository_file.arc_repo]
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/actions-runner-controller/helmrelease-actions-runner-controller.yaml")
  content             = file("${path.module}/../../platform-files/platform/actions-runner-controller/helmrelease-actions-runner-controller.yaml")
}


resource "time_sleep" "wait_for_arc_sync" {
  create_duration = "2m"
}


# Create self-hosted-runners secret
resource "kubernetes_secret_v1" "container-repository-secret" {
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
  depends_on = [time_sleep.wait_for_arc_sync, kubernetes_secret_v1.container-repository-secret]
  repository = var.repository_name
  branch     = var.branch
  file       = format("%s%s", var.target_path, "/platform-files/workloads/github-runners/startmeup-runner.yaml")
  content    = file("${path.module}/../../platform-files/workloads/github-runners/startmeup-runner.yaml")
}