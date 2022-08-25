terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
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
resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress-controller"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"

  set {
    name  = "externalTrafficPolicy"
    value = "Cluster"
  }
  version = "9.3.0"
}

resource "kubernetes_namespace" "cm" {
  metadata {
    name = "cert-manager"
  }
}


resource "helm_release" "cert-manager" {
  create_namespace = false
  namespace = "cert-manager"
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version = "v1.9.1"

  values = [file("cert-manager-values.yaml")]
}

data "kubernetes_service_v1" "load_balancer_nginx" {
  depends_on = [helm_release.nginx-ingress]
  metadata {
    name = "nginx-ingress-controller"
  }
}


resource "kubernetes_manifest" "letsencrypt-issuer" {
  depends_on = [helm_release.cert-manager]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name"      = "letsencrypt-issuer"
    }
    "spec" = {
      "acme" = {
        "email" = "umer.altaf@unimelb.edu.au"
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-cluster-issuer-key"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" ={
                "class" = "nginx"
              }
            }
          }
        ]
      }
    }

  }
}




resource "kubernetes_deployment_v1" "my-deployment" {
  metadata {
    name = "my-app"
    labels = {
      app = "my-myapp"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "my-app"
      }
    }
    replicas = "2"
    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }
      spec {
        container {
          name = "my-app"
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
      app = "my-app"
    }
  }

  spec {
    selector = {
      app = "my-app"
    }
    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "letsencrypt-certificate" {
  depends_on = [helm_release.cert-manager]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "my-app"
      "namespace" = "default"
    }
    "spec" = {
      "dnsNames" = ["${var.service_domain_name}"]
      "secretName" = "my-app-tls"
      "issuerRef" = {
        "name" = "letsencrypt-issuer"
        "kind" = "ClusterIssuer"
      }
    }
  }
}


resource "openstack_dns_recordset_v2" "domain" {
  depends_on = [helm_release.nginx-ingress, data.kubernetes_service_v1.load_balancer_nginx]
  name    = format("%s%s",var.service_domain_name,".")
  zone_id = "92b7daf1-6669-41e9-8d80-14f6cf644703"
  ttl = 30
  type = "A"
  records = [data.kubernetes_service_v1.load_balancer_nginx.status.0.load_balancer.0.ingress.0.ip]
}


resource "kubernetes_ingress_v1" "my-app" {
  wait_for_load_balancer = true
  metadata {
    name = "my-app"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
#      "cert-manager.io/cluster-issuer" = "letsencrypt-issuer"
    }
  }
  spec {
    tls {
      secret_name = "my-app-tls"
      hosts = [var.service_domain_name]
    }
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
