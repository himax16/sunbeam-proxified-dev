variable "nb_vm" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 3
}

variable "use_proxy" {
  description = "Whether to deploy a squid proxy and route traffic through it"
  type        = bool
  default     = false
}

variable "ssh_import_id" {
  description = "List of ssh-import-id entries for cloud-init users"
  type        = list(string)
  default     = ["lp:himax16", "gh:himax16"]
}