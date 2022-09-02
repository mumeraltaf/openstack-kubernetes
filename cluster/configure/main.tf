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


# Install cert-manager CRDs into the cluster
## doing it here because helm install of the release depends on this in addons-terraform
resource "null_resource" "install_cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml"
    environment = {
      KUBECONFIG = var.kube_config
    }
  }
}