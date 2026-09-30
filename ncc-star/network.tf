## center: the NVA and its load balancer
resource "google_compute_network" "center" {
  name                    = "${var.name_prefix}-center"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "center" {
  name          = "${var.name_prefix}-center"
  network       = google_compute_network.center.id
  region        = var.region
  ip_cidr_range = local.center_cidr
}

resource "google_compute_firewall" "center_ssh" {
  name          = "${var.name_prefix}-center-allow-ssh"
  network       = google_compute_network.center.id
  source_ranges = var.ssh_source_ranges
  target_tags   = ["${var.name_prefix}-nva"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# load balancer health checks come from Google's health check ranges
resource "google_compute_firewall" "center_health_check" {
  name          = "${var.name_prefix}-center-allow-health-check"
  network       = google_compute_network.center.id
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["${var.name_prefix}-nva"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# edge traffic reaches the NVA with its original source address
resource "google_compute_firewall" "center_from_edges" {
  name          = "${var.name_prefix}-center-allow-edges"
  network       = google_compute_network.center.id
  source_ranges = [local.edge_supernet]
  target_tags   = ["${var.name_prefix}-nva"]
  allow {
    protocol = "all"
  }
}

## edges: one VPC per test workload
resource "google_compute_network" "edge" {
  for_each                = local.edges
  name                    = "${var.name_prefix}-${each.key}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "edge" {
  for_each      = local.edges
  name          = "${var.name_prefix}-${each.key}"
  network       = google_compute_network.edge[each.key].id
  region        = var.region
  ip_cidr_range = each.value.cidr
}

# other edges arrive through the NVA with their original source address
resource "google_compute_firewall" "edge_from_edges" {
  for_each      = local.edges
  name          = "${var.name_prefix}-${each.key}-allow-edges"
  network       = google_compute_network.edge[each.key].id
  source_ranges = [local.edge_supernet]
  allow {
    protocol = "all"
  }
}

# ssh (jumping through the NVA) and ping from the center
resource "google_compute_firewall" "edge_from_center" {
  for_each      = local.edges
  name          = "${var.name_prefix}-${each.key}-allow-center"
  network       = google_compute_network.edge[each.key].id
  source_ranges = [local.center_cidr]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "icmp"
  }
}
