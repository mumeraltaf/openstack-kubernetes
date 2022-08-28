variable "kube_config" {
  type        = string
  description = "Path to Kubernetes Cluster Config file"
  default = "/Users/maalt/work/playpen/openstack-kubernetes/cluster/secret/config"
}

variable "cluster_url" {
  type        = string
  description = "Domain name in already existing DNS Zone on OpenStack"
  default = "kcluster3.aurin-prod.cloud.edu.au"
}