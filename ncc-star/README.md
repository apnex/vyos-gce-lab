## SYN
A Network Connectivity Center star topology on GCE: a center VPC with a VyOS network virtual appliance (NVA) behind an internal passthrough load balancer, and two edge VPCs whose test VMs reach each other only through the NVA.\
The NVA is deployed with [`mod-gce-vyos`](https://github.com/apnex/mod-gce-vyos); the image comes from [`mod-vyos-image`](https://github.com/apnex/mod-vyos-image).

```
                           NCC hub  (preset_topology = STAR)
        edge group                   center group                  edge group
  +------------------+     +-----------------------------+     +------------------+
  | edge-a VPC       |     | center VPC   10.30.0.0/24   |     | edge-b VPC       |
  | 10.20.1.0/24     |     |                             |     | 10.20.2.0/24     |
  |   vm-a .10       |     |  ilb forwarding rule .100   |     |   vm-b .10       |
  |                  |     |              |              |     |                  |
  | 10.20.0.0/16 ---------->     [ nva .10 ]  <------------- 10.20.0.0/16        |
  | via ilb .100     |     |  one-arm, can_ip_forward    |     | via ilb .100     |
  +------------------+     +-----------------------------+     +------------------+
```

### terraform.tfvars
```
project_id		= "my-project"
region			= "us-central1"
zone			= "us-central1-a"
ssh_source_ranges	= ["203.0.113.10/32"]	# your public ip
image			= null			# or an existing image / family path; null builds one
```

### apply
```
terraform init
terraform plan
terraform apply -auto-approve
```

### login
```
./login.sh nva
./login.sh vm-a
./login.sh vm-b
```

### verify
Edge to edge goes through the NVA (ttl 63), edge to center is direct (ttl 64).
```
./login.sh vm-a ping -c 3 10.20.2.10
./login.sh vm-a ping -c 3 10.30.0.10
./login.sh nva sudo tcpdump -ni eth0 -c 8 icmp and host 10.20.2.10
```

The hub carries subnet routes only: the edge route table holds the center subnet, never the other edge or a static route.
```
gcloud network-connectivity hubs route-tables routes list --hub=vyos-ncc-hub --route_table=edge
gcloud network-connectivity hubs route-tables routes list --hub=vyos-ncc-hub --route_table=center
```

### layout
- `main.tf` - topology (addressing, the routes sent to the NVA) and the image
- `network.tf` - center and edge VPCs, subnets and firewall rules
- `ncc.tf` - star hub and the center and edge spokes
- `nva.tf` - VyOS NVA, instance group, health check, backend service and forwarding rule
- `routes.tf` - edge static routes to the load balancer, and the center-only demonstration route
- `vms.tf` - Debian test VM per edge
- `login.sh` - ssh into the NVA, or into a test VM through the NVA

### notes
- Needs Terraform, `jq` for `login.sh`, and Google credentials that can manage Network Connectivity Center, networks, load balancers and instances
- NCC hubs do not exchange static routes, so each edge VPC carries its own route to the load balancer in the center spoke; the routes are defined once in `local.nva_routes` and created in every edge
- `center_only_route = true` adds the same kind of route in the center VPC only; the edges never learn it, which shows the point above
- Load balancer health checks are addressed to the forwarding rule IP; the image's Google guest agent adds it as a local route, as on standard GCE images (`mod-vyos-image` with `google_guest_agent = true`)
- A replaced NVA keeps its name but drops out of the instance group; membership is re-created from its instance id
- When all backends fail health checks, routes through the load balancer stay in effect
- `image = null` builds the image pipeline with `mod-vyos-image` defaults; in a project that already runs that pipeline, pass its image instead
