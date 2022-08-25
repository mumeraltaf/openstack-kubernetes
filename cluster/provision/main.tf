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
#
#
#resource "kubernetes_persistent_volume_claim_v1" "kube-storage-claim" {
#  metadata {
#    name = "kube-storage-claim"
#    namespace = "default"
#  }
#  spec {
#    storage_class_name = "default"
#    access_modes = ["ReadWriteOnce"]
#    resources {
#      requests = {
#        storage = var.volume_claim_size
#      }
#    }
#  }
#  timeouts {
#    create = "30m"
#  }
#}