variable "kube_config" {
  type        = string
  description = "Path to Kubernetes Cluster Config file"
  default = "/Users/maalt/work/playpen/openstack-kubernetes/cluster/secret/config"
}

variable "service_domain_name" {
  type        = string
  description = "Domain name in already existing DNS Zone on OpenStack"
  default = "cluster-nginx.aurin-prod.cloud.edu.au"
}