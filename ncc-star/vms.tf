## test workloads: one small Debian VM per edge, no external address; reached by
## jumping through the NVA (the center learns every edge subnet from NCC)
resource "tls_private_key" "vm" {
  algorithm = "ED25519"
}

resource "google_compute_instance" "vm" {
  for_each     = local.edges
  name         = "${var.name_prefix}-${each.key}-vm"
  zone         = var.zone
  machine_type = var.vm_machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.edge[each.key].id
    network_ip = each.value.vm_ip
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    ssh-keys       = "lab:${trimspace(tls_private_key.vm.public_key_openssh)} lab"
    enable-oslogin = "FALSE"
  }
}

## private keys for login.sh
resource "local_sensitive_file" "nva_key" {
  content              = module.nva.ssh_private_key
  filename             = "${path.module}/.ssh/nva"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_sensitive_file" "vm_key" {
  content              = tls_private_key.vm.private_key_openssh
  filename             = "${path.module}/.ssh/vm"
  file_permission      = "0600"
  directory_permission = "0700"
}
