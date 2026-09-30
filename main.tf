## topology: two routers, eth0 in mgmt (ssh), eth1 in transit with fixed addresses,
## a GRE tunnel between them over transit and eBGP across the tunnel for their loopbacks
locals {
  mgmt_cidr    = "10.10.0.0/24"
  transit_cidr = "10.255.0.0/24"

  routers = {
    router-a = {
      asn        = 65001
      transit_ip = "10.255.0.2"
      loopback   = "10.100.1.1"
      tunnel_ip  = "10.200.0.1"
      peer       = "router-b"
    }
    router-b = {
      asn        = 65002
      transit_ip = "10.255.0.3"
      loopback   = "10.100.2.1"
      tunnel_ip  = "10.200.0.2"
      peer       = "router-a"
    }
  }

  image = var.image != null ? var.image : module.vyos_image[0].image_self_link
}

## image: built here only when none is supplied
module "vyos_image" {
  source     = "github.com/apnex/mod-vyos-image"
  count      = var.image == null ? 1 : 0
  project_id = var.project_id
  region     = var.region
}

## routers
module "router" {
  source       = "github.com/apnex/mod-gce-vyos"
  for_each     = local.routers
  project_id   = var.project_id
  zone         = var.zone
  name         = "${var.name_prefix}-${each.key}"
  machine_type = var.machine_type
  image        = local.image
  tags         = ["${var.name_prefix}-router"]
  network_interfaces = [
    {
      subnetwork  = google_compute_subnetwork.mgmt.id
      external_ip = true
      description = "mgmt"
    },
    {
      subnetwork  = google_compute_subnetwork.transit.id
      network_ip  = each.value.transit_ip
      description = "transit"
    },
  ]
  vyos_config = templatefile("${path.module}/templates/router.cfg.tftpl", {
    name            = each.key
    asn             = each.value.asn
    transit_ip      = each.value.transit_ip
    loopback        = each.value.loopback
    tunnel_ip       = each.value.tunnel_ip
    peer            = each.value.peer
    peer_asn        = local.routers[each.value.peer].asn
    peer_transit_ip = local.routers[each.value.peer].transit_ip
    peer_tunnel_ip  = local.routers[each.value.peer].tunnel_ip
  })
}

## one private key file per router for login.sh
resource "local_sensitive_file" "ssh_private_key" {
  for_each             = local.routers
  content              = module.router[each.key].ssh_private_key
  filename             = "${path.module}/.ssh/${each.key}"
  file_permission      = "0600"
  directory_permission = "0700"
}
