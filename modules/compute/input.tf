variable "hostname" {}
variable "management_domain" {}
variable "management_net" {}
variable "management_dns" {}
variable "compute_nets" {}
variable "proxy_url" {}
variable "proxy_ip" {}
variable "no_proxy" {}
variable "cores" {}
variable "memory" {}
variable "use_proxy" {
  type = bool
}
variable "nb_osd" {
  default = 3
}
