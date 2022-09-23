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

variable "github_owner" {
  type        = string
  description = "github owner"
}

variable "github_token" {
  type        = string
  description = "github token"
}

variable "repository_name" {
  type        = string
  default     = "os-ccm-flux"
  description = "github repository name"
}

variable "repository_visibility" {
  type        = string
  default     = "private"
  description = "How visible is the github repo"
}

variable "branch" {
  type        = string
  default     = "main"
  description = "branch name"
}

variable "target_path" {
  type        = string
  default     = "dev-cluster"
  description = "flux sync target path"
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

