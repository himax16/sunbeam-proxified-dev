variable "hostname" {}
variable "management_domain" {}
variable "management_net" {}
variable "management_dns" {}
variable "compute_nets" {}
variable "proxy_url" {}
variable "proxy_ip" {}
variable "no_proxy" {}
variable "cores" {
  type        = number
  description = "Number of CPU cores"
}
variable "memory" {
  type        = string
  description = "Memory size with units (e.g., 20GiB)"
}
variable "use_proxy" {
  type = bool
}
variable "nb_osd" {
  default = 3
}
variable "ssh_import_id" {
  type = list(string)
}