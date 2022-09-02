# Setup all required providers
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

##############################

# Install nginx-ingress-controller
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


# Create cert-manager namespace
resource "kubernetes_namespace" "cm" {
  metadata {
    name = "cert-manager"
  }
}

# Install cert-manager
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

resource "openstack_dns_recordset_v2" "domain" {
  depends_on = [helm_release.nginx-ingress, data.kubernetes_service_v1.load_balancer_nginx]
  name    = format("%s%s%s","*.",var.cluster_url,".")
  zone_id = "92b7daf1-6669-41e9-8d80-14f6cf644703"
  ttl = 30
  type = "A"
  records = [data.kubernetes_service_v1.load_balancer_nginx.status.0.load_balancer.0.ingress.0.ip]
}


# Create the letsencrypt cluster issuer
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



# Create actions-runner-system namespace
resource "kubernetes_namespace" "actions-runner-system-namespace" {
  metadata {
    name = "actions-runner-system"
  }
}

#kubectl create secret generic controller-manager \
#-n actions-runner-system \
#--from-literal=github_app_id=${APP_ID} \
#--from-literal=github_app_installation_id=${INSTALLATION_ID} \
#--from-file=github_app_private_key=${PRIVATE_KEY_FILE_PATH}

# Create actions-runner-system namespace
resource "kubernetes_secret_v1" "actions-runner-controller-manager-secret" {
  depends_on = [kubernetes_namespace.actions-runner-system-namespace]
  metadata {
    name = "controller-manager"
    namespace = "actions-runner-system"
  }
  data = {
    "github_app_id" = "234370"
    "github_app_installation_id" = "28836203"
    "github_app_private_key" = file("/Users/maalt/Desktop/k8_secrets/kube-runner-umer-cluser.2022-09-02.private-key.pem")
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

# Install github runner helm
resource "helm_release" "actions-runner" {
  depends_on = [kubernetes_manifest.letsencrypt-issuer, kubernetes_secret_v1.actions-runner-controller-manager-secret]

  name             = "actions-runner-controller"
  namespace        = "actions-runner-system"
  create_namespace = false
  wait             = true
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
}