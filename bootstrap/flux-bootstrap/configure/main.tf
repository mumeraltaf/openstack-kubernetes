terraform {
  required_version = ">= 1.3.0"

  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

resource "github_repository_file" "cinder_storage_class" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/cinder-storage-class/cinder-storage-class.yaml")
  content             = file("${path.module}/platform-files/platform/cinder-storage-class/cinder-storage-class.yaml")
}


resource "github_repository_file" "cert_manager_repo" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/cert-manager/helmrepo-cert-manager.yaml")
  content             = file("${path.module}/platform-files/platform/cert-manager/helmrepo-cert-manager.yaml")
}

resource "github_repository_file" "cert_manager_helm_release" {
  depends_on = [github_repository_file.cert_manager_repo]
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/cert-manager/helmrelease-cert-manager.yaml")
  content             = file("${path.module}/platform-files/platform/cert-manager/helmrelease-cert-manager.yaml")
}


resource "github_repository_file" "argocd_ns" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/argocd/argo-ns.yaml")
  content             = file("${path.module}/platform-files/platform/argocd/argo-ns.yaml")
}

resource "github_repository_file" "argocd_kustomization" {
  depends_on = [github_repository_file.argocd_ns]
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/argocd/kustomization.yaml")
  content             = file("${path.module}/platform-files/platform/argocd/kustomization.yaml")
}

resource "github_repository_file" "arc_repo" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/actions-runner-controller/helmrepo-actions-runner-controller.yaml")
  content             = file("${path.module}/platform-files/platform/actions-runner-controller/helmrepo-actions-runner-controller.yaml")
}

resource "github_repository_file" "arc_release" {
  depends_on = [github_repository_file.arc_repo]
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/actions-runner-controller/helmrelease-actions-runner-controller.yaml")
  content             = file("${path.module}/platform-files/platform/actions-runner-controller/helmrelease-actions-runner-controller.yaml")
}