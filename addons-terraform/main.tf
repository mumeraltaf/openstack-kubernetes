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

# Create github app secret
resource "kubernetes_secret_v1" "actions-runner-controller-manager-secret" {
  depends_on = [kubernetes_namespace.actions-runner-system-namespace]
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


# Create self-hosted-runners namespace
resource "kubernetes_namespace" "self-hosted-runners-namespace" {
  metadata {
    name = "self-hosted-runners"
  }
}

# Create self-hosted-runners secret
resource "kubernetes_secret_v1" "container-repository-secret" {
  depends_on = [kubernetes_namespace.self-hosted-runners-namespace]
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
