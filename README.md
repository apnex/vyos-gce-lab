## SYN
A VyOS routing lab on GCE: two routers with a management and a transit network, a GRE tunnel between them, and eBGP across the tunnel exchanging loopbacks.\
Routers are deployed with [`mod-gce-vyos`](https://github.com/apnex/mod-gce-vyos); the image comes from [`mod-vyos-image`](https://github.com/apnex/mod-vyos-image).

```
                  mgmt 10.10.0.0/24  (ssh, external ips)
        +---------------+-----------------------+---------------+
                        | eth0                  | eth0
                +-------+-------+       +-------+-------+
                |   router-a    |       |   router-b    |
                |   AS 65001    |       |   AS 65002    |
                | lo 10.100.1.1 |       | lo 10.100.2.1 |
                +-------+-------+       +-------+-------+
                        | eth1 .2               | eth1 .3
        +---------------+-----------------------+---------------+
                  transit 10.255.0.0/24
                        |=======================|
                          tun0 GRE 10.200.0.0/30
                          eBGP 10.100.1.1 <-> 10.100.2.1
```

### terraform.tfvars
```
project_id		= "my-project"
region			= "australia-southeast1"
zone			= "australia-southeast1-a"
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
./login.sh router-a
./login.sh router-b
```

### verify
```
./login.sh router-a /opt/vyatta/bin/vyatta-op-cmd-wrapper show ip bgp summary
./login.sh router-a /opt/vyatta/bin/vyatta-op-cmd-wrapper show ip route bgp
./login.sh router-a ping -c 3 -I 10.100.1.1 10.100.2.1
```

### layout
- `main.tf` - topology (addressing, ASNs, peers) and the routers
- `network.tf` - mgmt and transit VPCs, subnets and firewall rules
- `templates/router.cfg.tftpl` - per-router VyOS config (loopback, GRE, eBGP)
- `login.sh` - ssh into a router from the terraform outputs

### notes
- Needs Terraform, `jq` for `login.sh`, and Google credentials that can create networks and instances (plus services, service accounts and IAM when the image is built here)
- `image = null` builds the image pipeline with `mod-vyos-image` defaults; in a project that already runs that pipeline, pass its image instead
- Router config is applied on first boot; changing the template or topology replaces the routers
- Leaf values in the template must be single-quoted (`address '10.0.0.1/32'`)
- A GCE VPC routes by destination, so prefixes learned over BGP are only reachable across the GRE tunnel, not natively over transit
- Designed as the base for Network Connectivity Center router appliances and Cloud Router peering
