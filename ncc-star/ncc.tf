## NCC star hub: edges exchange subnet routes with the center, never with each other
resource "google_network_connectivity_hub" "hub" {
  name            = "${var.name_prefix}-hub"
  preset_topology = "STAR"
  depends_on      = [google_project_service.networkconnectivity]
}

resource "google_network_connectivity_spoke" "center" {
  name     = "${var.name_prefix}-center"
  location = "global"
  hub      = google_network_connectivity_hub.hub.id
  group    = "${google_network_connectivity_hub.hub.id}/groups/center"
  linked_vpc_network {
    uri = google_compute_network.center.self_link
  }
}

resource "google_network_connectivity_spoke" "edge" {
  for_each = local.edges
  name     = "${var.name_prefix}-${each.key}"
  location = "global"
  hub      = google_network_connectivity_hub.hub.id
  group    = "${google_network_connectivity_hub.hub.id}/groups/edge"
  linked_vpc_network {
    uri = google_compute_network.edge[each.key].self_link
  }
}
