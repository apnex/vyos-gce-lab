## topology: NCC star hub; center VPC holds a VyOS NVA behind an internal passthrough NLB;
## edge VPCs hold test VMs and reach each other only through the NVA
locals {
  center_cidr = "10.30.0.0/24"
  nva_ip      = "10.30.0.10"
  ilb_ip      = "10.30.0.100"

  edges = {
    edge-a = { cidr = "10.20.1.0/24", vm_ip = "10.20.1.10" }
    edge-b = { cidr = "10.20.2.0/24", vm_ip = "10.20.2.10" }
  }

  # NCC does not exchange static routes, so every edge carries these routes itself,
  # each pointing at the ILB in the center spoke; defined once here, stamped into every edge
  edge_supernet = "10.20.0.0/16"
  nva_routes    = [local.edge_supernet]
  edge_routes = merge([
    for edge in keys(local.edges) : {
      for dest in local.nva_routes : "${edge}/${dest}" => { edge = edge, dest = dest }
    }
  ]...)

  # destination for the center-only route that demonstrates static routes are not exported
  center_only_dest = "192.168.99.0/24"

  image = var.image != null ? var.image : module.vyos_image[0].image_self_link
}

resource "google_project_service" "networkconnectivity" {
  project            = var.project_id
  service            = "networkconnectivity.googleapis.com"
  disable_on_destroy = false
}

## image: built here only when none is supplied
module "vyos_image" {
  source     = "github.com/apnex/mod-vyos-image"
  count      = var.image == null ? 1 : 0
  project_id = var.project_id
  region     = var.region
}
