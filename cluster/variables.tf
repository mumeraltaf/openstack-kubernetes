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