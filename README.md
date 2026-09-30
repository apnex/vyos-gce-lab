## SYN
VyOS routing labs on GCE, one directory per topology; each directory is its own Terraform root with a `login.sh`.\
Routers are deployed with [`mod-gce-vyos`](https://github.com/apnex/mod-gce-vyos); the image comes from [`mod-vyos-image`](https://github.com/apnex/mod-vyos-image).

| Topology | What it shows |
|---|---|
| [`bgp-gre`](bgp-gre) | Two routers with management and transit networks, a GRE tunnel between them, and eBGP exchanging loopbacks |
| [`ncc-star`](ncc-star) | NCC star hub: a center VyOS NVA behind an internal load balancer, and two edge VPCs that reach each other only through it |

### apply
```
cd <topology>
terraform init
terraform plan
terraform apply -auto-approve
```
