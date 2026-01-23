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
