variable "nb_vm" {
  default = 1
}

variable "use_proxy" {
  description = "Whether to deploy a squid proxy and route traffic through it"
  type        = bool
  default     = true
}
