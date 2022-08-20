variable "secrets_directory" {
  type        = string
  description = "Path to Aurin Github account private key"
  default = "/Users/maalt/Desktop/adp-deploy-secrets"
}

variable "ssh_key_file" {
  type = string
  description = "Relative path to the ssh key file for the instance"
  default = "/nectar/adp-terraform-key"
}

variable "kube_config" {
  type        = string
  description = "Path to Kubernetes Cluster Config file"
  default = "/Users/maalt/work/playpen/openstack-kubernetes/cluster/secret/config"
}