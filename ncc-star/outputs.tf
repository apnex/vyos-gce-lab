output "image" {
  description = "VyOS image the NVA boots from."
  value       = local.image
}

output "hub" {
  description = "NCC hub id."
  value       = google_network_connectivity_hub.hub.id
}

output "ilb_ip" {
  description = "Next hop address of the load balancer in front of the NVA."
  value       = local.ilb_ip
}

output "hosts" {
  description = "Login details for the NVA and each test VM, as read by login.sh; test VMs are reached through the NVA."
  value = merge(
    {
      nva = {
        address              = module.nva.address
        internal_ip          = local.nva_ip
        ssh_user             = module.nva.ssh_user
        ssh_private_key_file = abspath(local_sensitive_file.nva_key.filename)
        jump                 = false
      }
    },
    {
      for k, v in local.edges : "vm-${trimprefix(k, "edge-")}" => {
        address              = v.vm_ip
        internal_ip          = v.vm_ip
        ssh_user             = "lab"
        ssh_private_key_file = abspath(local_sensitive_file.vm_key.filename)
        jump                 = true
      }
    }
  )
}

output "edge_routes" {
  description = "Static routes stamped into each edge VPC, pointing at the load balancer."
  value       = { for k, r in google_compute_route.edge_to_nva : k => "${r.dest_range} via ${r.next_hop_ilb}" }
}
