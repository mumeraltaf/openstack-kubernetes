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

resource "github_repository_file" "nginx_ingress_repo" {
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/nginx-ingress-controller/helmrepo-ingress-nginx.yaml")
  content             = file("${path.module}/platform-files/platform/nginx-ingress-controller/helmrepo-ingress-nginx.yaml")
}

resource "github_repository_file" "nginx_ingress_helm_release" {
  depends_on = [github_repository_file.nginx_ingress_repo]
  repository          = var.repository_name
  branch              = var.branch
  file                = format("%s%s",var.target_path,"/platform-files/platform/nginx-ingress-controller/helmrelease-ingress-nginx.yaml")
  content             = file("${path.module}/platform-files/platform/nginx-ingress-controller/helmrelease-ingress-nginx.yaml")
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


# Create self-hosted-runners namespace
resource "kubernetes_namespace" "actions-runner-system" {
  metadata {
    name = "actions-runner-system"
  }
}

# Create github app secret
resource "kubernetes_secret_v1" "actions-runner-controller-manager-secret" {
    depends_on = [kubernetes_namespace.actions-runner-system]
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
