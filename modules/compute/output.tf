output "ip" {
  value = lxd_instance.compute.ipv4_address
}

output "name" {
  value = lxd_instance.compute.name
}

output "fqdn" {
  value = local.fqdn
}

output "osds" {
  value = lxd_volume.osd[*].name
}
