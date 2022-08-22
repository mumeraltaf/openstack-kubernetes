terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.6.0"
    }
  }






}
provider "kubernetes" {
  config_path = var.kube_config
}
provider "helm" {
  kubernetes {
    config_path = var.kube_config
  }
}
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"

  set {
    name  = "externalTrafficPolicy"
    value = "Cluster"
  }
}




resource "kubernetes_service_v1" "ingress-service" {
  metadata {
    name = "ingress-service"
  }
  spec {
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}


resource "kubernetes_ingress_v1" "my-ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "my-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = kubernetes_service_v1.ingress-service.metadata.0.name
              port {
                  number = 8080
              }
            }
          }
        }
      }
    }
  }
}




data "kubernetes_service_v1" "lb" {
  metadata {
    name = "nginx-ingress-controller"
  }
}

output "ipthis" {
  value = data.kubernetes_service_v1.lb.status.0.load_balancer.0.ingress.0.ip
}