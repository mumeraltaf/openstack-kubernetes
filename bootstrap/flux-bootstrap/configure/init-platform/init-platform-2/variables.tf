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