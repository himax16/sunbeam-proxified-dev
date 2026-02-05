
locals {
  no_proxy     = "localhost,127.0.0.1,.local,${local.restricted_domain},${local.restricted_net},${join(",", local.compute_nets)}"
  loadbalancer = "${cidrhost(local.restricted_net, local.restricted_allowed_dhcp_range[1] + 1)}-${cidrhost(local.restricted_net, -2)}"
  nameserver   = cidrhost(local.restricted_net, 1)
}

# Check total requested memory during plan phase
data "external" "memory_check" {
  program = ["bash", "${path.root}/scripts/check_mem.sh"]
  query = {
    memory_main  = var.memory_main
    memory_child = var.memory_child
    nb_vm        = var.nb_vm
  }
}
resource "null_resource" "memory_check" {
  triggers = {
    requested_kib = data.external.memory_check.result.requested_kib
    available_kib = data.external.memory_check.result.available_kib
  }
}

module "compute" {
  depends_on = [null_resource.proxy]
  source     = "./modules/compute"
  count      = var.nb_vm

  cores  = count.index == 0 ? var.ncore_main : var.ncore_child
  memory = count.index == 0 ? var.memory_main : var.memory_child

  hostname          = "bm${count.index}"
  management_domain = local.restricted_domain
  management_net    = lxd_network.restricted.name
  management_dns    = local.nameserver
  compute_nets      = [for n in lxd_network.computes : n.name]
  proxy_url         = local.proxy_url
  proxy_ip          = local.proxy_ip
  no_proxy          = local.no_proxy
  use_proxy         = var.use_proxy
  ssh_import_id     = var.ssh_import_id
}

resource "lxd_instance_file" "manifest" {
  depends_on = [module.compute]
  instance   = module.compute[0].name
  content = templatefile("${path.root}/templates/compute/manifest.yaml", {
    use_proxy          = var.use_proxy,
    proxy_url          = local.proxy_url,
    no_proxy           = local.no_proxy,
    restricted_network = local.restricted_net,
    restricted_domain  = local.restricted_domain,
    compute_network    = local.compute_nets[0],
    loadbalancer       = local.loadbalancer,
    nameservers        = local.nameserver
    compute_network    = local.compute_nets[0],
    compute_gateway    = cidrhost(local.compute_nets[0], 1),
    compute_range      = "${cidrhost(local.compute_nets[0], 2)}-${cidrhost(local.compute_nets[0], -2)}"
    osds               = { for compute in module.compute : compute.fqdn => join(",", formatlist("/dev/disk/by-id/scsi-SQEMU_QEMU_HARDDISK_lxd_%s", compute.osds)) }
  })
  target_path = "/home/ubuntu/manifest.yaml"
  mode        = "0644"
  uid         = 1000
  gid         = 1000

}
