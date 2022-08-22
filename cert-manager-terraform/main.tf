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
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.48.0"
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


#data "kubernetes_service_v1" "nginx_ingress" {
#  metadata {
#    name = "nginx-ingress-controller"
#  }
#}

#output "ipthis" {
#  value = data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.ip
#}



resource "kubernetes_deployment_v1" "my-deployment" {
  metadata {
    name = "my-deployment"
    labels = {
      app = "my-deployment"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "my-deployment"
      }
    }
    replicas = "2"
    template {
      metadata {
        labels = {
          app = "my-deployment"
        }
      }
      spec {
        container {
          name = "my-deployment"
          image = "gcr.io/kuar-demo/kuard-amd64:1"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}


resource "kubernetes_service_v1" "my-service" {
  metadata {
    name = "my-service"
    labels = {
      app = "my-deployment"
    }
  }

  spec {
    selector = {
      app = "my-deployment"
    }
    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}



data "kubernetes_service_v1" "load_balancer_nginx" {
  depends_on = [helm_release.nginx_ingress]
  metadata {
    name = "nginx-ingress-controller"
  }
}


resource "openstack_dns_recordset_v2" "domain" {
  depends_on = [helm_release.nginx_ingress, data.kubernetes_service_v1.load_balancer_nginx]
  name    = format("%s%s",var.service_domain_name,".")
  zone_id = "92b7daf1-6669-41e9-8d80-14f6cf644703"
  ttl = 30
  type = "A"
  records = [data.kubernetes_service_v1.load_balancer_nginx.status.0.load_balancer.0.ingress.0.ip]
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
      host = var.service_domain_name
      http {
        path {
          path = "/"
          backend {
            service {
              name = "my-service"
              port {
                  number = 80
              }
            }
          }
        }
      }
    }
  }
}
