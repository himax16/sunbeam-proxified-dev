variable "nb_vm" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 4
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

# Number of CPU cores for the main (bm0) VM
variable "ncore_main" {
  description = "Number of CPU cores for the main (bm0) VM"
  type        = number
  default     = 8
}

# Number of CPU cores for child (bm1..bmN) VMs
variable "ncore_child" {
  description = "Number of CPU cores for child (bm1..bmN) VMs"
  type        = number
  default     = 4
}

# Memory size with units for the main (bm0) VM
variable "memory_main" {
  description = "Memory for the main (bm0) VM (include units, e.g., 20GiB)"
  type        = string
  default     = "32GiB"
}

# Memory size with units for child (bm1..bmN) VMs
variable "memory_child" {
  description = "Memory for child (bm1..bmN) VMs (include units, e.g., 10GiB)"
  type        = string
  default     = "16GiB"
}