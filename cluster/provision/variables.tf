variable "kube_config" {
  type        = string
  description = "Path to Kubernetes Cluster Config file"
  default = "/Users/maalt/work/playpen/openstack-kubernetes/cluster/secret/config"
}

variable "volume_claim_size" {
  type        = string
  description = "Size of OpenStack Volume to Provision"
  default = "100Gi"
}