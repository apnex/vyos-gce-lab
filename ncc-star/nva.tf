## NVA: one VyOS router, one interface in the center VPC (one-arm: forwarded traffic
## leaves the way it came, via its default route to the center gateway)
module "nva" {
  source     = "github.com/apnex/mod-gce-vyos"
  project_id = var.project_id
  zone       = var.zone
  name       = "${var.name_prefix}-nva"
  image      = local.image
  tags       = ["${var.name_prefix}-nva"]
  network_interfaces = [
    {
      subnetwork  = google_compute_subnetwork.center.id
      network_ip  = local.nva_ip
      external_ip = true
      description = "center"
    },
  ]
  # load balancer health checks are addressed to the forwarding rule IP; the image's Google
  # guest agent adds it as a local route from instance metadata (forwarded IPs)
}

## internal passthrough NLB in front of the NVA; as a route next hop it forwards all
## protocols and ports regardless of the forwarding rule and backend service protocol
resource "google_compute_instance_group" "nva" {
  name = "${var.name_prefix}-nva"
  zone = var.zone
  # membership is managed by google_compute_instance_group_membership below
  lifecycle {
    ignore_changes = [instances]
  }
}

# a replaced NVA keeps its name and self link but silently drops out of the group, so
# membership is re-created whenever the instance's unique id changes
resource "terraform_data" "nva_instance" {
  input = module.nva.instance_id
}

resource "google_compute_instance_group_membership" "nva" {
  zone           = var.zone
  instance_group = google_compute_instance_group.nva.name
  instance       = module.nva.self_link
  lifecycle {
    replace_triggered_by = [terraform_data.nva_instance]
  }
}

resource "google_compute_health_check" "nva" {
  name = "${var.name_prefix}-nva"
  tcp_health_check {
    port = 22
  }
}

resource "google_compute_region_backend_service" "nva" {
  name                  = "${var.name_prefix}-nva"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  protocol              = "TCP"
  network               = google_compute_network.center.id
  health_checks         = [google_compute_health_check.nva.id]
  # no draining: otherwise removing a replaced NVA from the group waits out the 300s default
  connection_draining_timeout_sec = 0
  backend {
    group          = google_compute_instance_group.nva.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "nva" {
  name                  = "${var.name_prefix}-nva"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  all_ports             = true
  ip_address            = local.ilb_ip
  network               = google_compute_network.center.id
  subnetwork            = google_compute_subnetwork.center.id
  backend_service       = google_compute_region_backend_service.nva.id
}
