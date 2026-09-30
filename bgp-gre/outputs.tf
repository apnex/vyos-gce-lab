output "image" {
  description = "VyOS image the routers boot from."
  value       = local.image
}

output "routers" {
  description = "Per-router addressing and login details, as read by login.sh."
  value = {
    for k, r in local.routers : k => {
      address              = module.router[k].address
      ssh_user             = module.router[k].ssh_user
      ssh_private_key_file = abspath(local_sensitive_file.ssh_private_key[k].filename)
      asn                  = r.asn
      transit_ip           = r.transit_ip
      loopback             = r.loopback
      tunnel_ip            = r.tunnel_ip
      interfaces           = module.router[k].interfaces
      self_link            = module.router[k].self_link
      serial               = module.router[k].serial_console_command
    }
  }
}
