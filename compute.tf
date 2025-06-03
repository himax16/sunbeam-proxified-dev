
locals {
  no_proxy     = "localhost,127.0.0.1,.local,${local.restricted_domain},${local.restricted_net},${local.compute_net}"
  loadbalancer = "${cidrhost(local.restricted_net, local.restricted_allowed_dhcp_range[1] + 1)}-${cidrhost(local.restricted_net, -2)}"
  nameserver   = cidrhost(local.restricted_net, 1)
}

module "compute" {
  depends_on = [null_resource.proxy]
  source     = "./modules/compute"
  count      = var.nb_vm

  cores  = count.index == 0 ? "6" : "4"
  memory = count.index == 0 ? "16GiB" : "6GiB"

  hostname          = "bm${count.index}"
  management_domain = local.restricted_domain
  management_net    = lxd_network.restricted.name
  management_dns    = local.nameserver
  compute_net       = lxd_network.compute.name
  proxy_url         = local.proxy_url
  proxy_ip          = local.proxy_ip
  no_proxy          = local.no_proxy
}

resource "lxd_instance_file" "manifest" {
  depends_on = [module.compute]
  instance   = module.compute[0].name
  content = templatefile("${path.root}/templates/compute/manifest.yaml", {
    proxy_url          = local.proxy_url,
    no_proxy           = local.no_proxy,
    restricted_network = local.restricted_net,
    restricted_domain  = local.restricted_domain,
    compute_network    = local.compute_net,
    loadbalancer       = local.loadbalancer,
    nameservers        = local.nameserver
    compute_network    = local.compute_net,
    compute_gateway    = cidrhost(local.compute_net, 1),
    compute_range      = "${cidrhost(local.compute_net, 2)}-${cidrhost(local.compute_net, -2)}"
    osds               = { for compute in module.compute : compute.fqdn => join(",", formatlist("/dev/disk/by-id/scsi-SQEMU_QEMU_HARDDISK_lxd_%s", compute.osds)) }
  })
  target_path = "/home/ubuntu/manifest.yaml"
  mode        = "0644"
  uid         = 1000
  gid         = 1000

}
