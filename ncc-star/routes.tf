## edge routes to the NVA: a static route in an edge spoke may use a next hop ILB in a
## center spoke, addressed by IP; the edge's own subnet and the center's subnet (learned
## from NCC) are more specific, so only other-edge traffic takes these routes
resource "google_compute_route" "edge_to_nva" {
  for_each     = local.edge_routes
  name         = "${var.name_prefix}-${each.value.edge}-${replace(replace(each.value.dest, ".", "-"), "/", "-")}"
  network      = google_compute_network.edge[each.value.edge].id
  dest_range   = each.value.dest
  next_hop_ilb = local.ilb_ip
  priority     = 1000
  depends_on   = [google_network_connectivity_spoke.center, google_network_connectivity_spoke.edge, google_compute_forwarding_rule.nva]
}

## demonstration: the same kind of route created in the center spoke only; NCC hubs do not
## exchange static routes, so the edges never learn it
resource "google_compute_route" "center_only" {
  count        = var.center_only_route ? 1 : 0
  name         = "${var.name_prefix}-center-only-${replace(replace(local.center_only_dest, ".", "-"), "/", "-")}"
  network      = google_compute_network.center.id
  dest_range   = local.center_only_dest
  next_hop_ilb = local.ilb_ip
  priority     = 1000
  depends_on   = [google_compute_forwarding_rule.nva]
}
