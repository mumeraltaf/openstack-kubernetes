variable "kube_config" {
  type        = string
  description = "Path to Kubernetes Cluster Config file"
  default = "/Users/maalt/work/playpen/terraform-openstack-rke2/examples/cloud-controller-manager/rke2.yaml"
}