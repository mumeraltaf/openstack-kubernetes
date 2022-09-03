variable "kube_config" {
  type        = string
  description = "Path to Kubernetes Cluster Config file"
  default = "/Users/maalt/work/playpen/openstack-kubernetes/cluster/secret/config"
}

variable "dns_zone_id" {
  type        = string
  description = "DNS Zone ID allocated in OpenStack"
}

variable "cluster_url" {
  type        = string
  description = "Base Hostname that is part of the assigned zone"
}

variable "github_app_id" {
  type        = string
  description = "GitHub App Id for the github runner"
}

variable "github_app_installation_id" {
  type        = string
  description = "GitHub App Installation Id for the github runner"
}

variable "github_app_private_key_path" {
  type        = string
  description = "Path to the GitHub App private key file (.pem) for the github runner"
}

variable "container_registry" {
  type        = string
  description = "URL to the container registry"
}

variable "registry_username" {
  type        = string
  description = "Username for the container registry"
}

variable "registry_password" {
  type        = string
  description = "Password for the container registry"
}