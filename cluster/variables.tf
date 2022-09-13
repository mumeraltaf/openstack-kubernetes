variable "cluster_name" {
  type    = string
  default = "os-ccm"
}

variable "dns_zone_id" {
  type        = string
  description = "DNS Zone ID allocated in OpenStack"
}

variable "dns_base_url" {
  type        = string
  description = "Base Hostname that is part of the assigned zone"
}
