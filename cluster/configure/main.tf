terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
provider "kubernetes" {
  config_path = var.kube_config
}
resource "kubernetes_storage_class_v1" "kube_storage_class" {
  metadata {
    name = "default"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  parameters = {
    availability = "melbourne-qh2"
  }
  storage_provisioner = "cinder.csi.openstack.org"
}


# Install cert-manager CRDs into the cluster, comment out if doing manual install of cert-manager
resource "null_resource" "install_cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml"
    environment = {
      KUBECONFIG = var.kube_config
    }
  }
}

# Install argo cd namespace
resource "null_resource" "install_argo-cd-namespace" {
  provisioner "local-exec" {
    command = "kubectl create namespace argocd"
    environment = {
      KUBECONFIG = var.kube_config
    }
  }
}

# Install argo cd
resource "null_resource" "install_argo-cd" {
  provisioner "local-exec" {
    command = "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    environment = {
      KUBECONFIG = var.kube_config
    }
  }
}