## mgmt: eth0 of every router; external IPs and SSH
resource "google_compute_network" "mgmt" {
  name                    = "${var.name_prefix}-mgmt"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name_prefix}-mgmt"
  network       = google_compute_network.mgmt.id
  region        = var.region
  ip_cidr_range = local.mgmt_cidr
}

resource "google_compute_firewall" "mgmt_ssh" {
  name          = "${var.name_prefix}-mgmt-allow-ssh"
  network       = google_compute_network.mgmt.id
  source_ranges = var.ssh_source_ranges
  target_tags   = ["${var.name_prefix}-router"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

## transit: eth1 of every router; carries the GRE tunnel between them
resource "google_compute_network" "transit" {
  name                    = "${var.name_prefix}-transit"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "transit" {
  name          = "${var.name_prefix}-transit"
  network       = google_compute_network.transit.id
  region        = var.region
  ip_cidr_range = local.transit_cidr
}

# custom VPCs deny internal traffic by default; routers may exchange anything on transit
resource "google_compute_firewall" "transit_internal" {
  name          = "${var.name_prefix}-transit-allow-internal"
  network       = google_compute_network.transit.id
  source_ranges = [local.transit_cidr]
  target_tags   = ["${var.name_prefix}-router"]
  allow {
    protocol = "all"
  }
}
