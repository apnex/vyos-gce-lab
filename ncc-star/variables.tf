variable "project_id" {
  description = "Project for the lab."
  type        = string
}

variable "region" {
  description = "Region for every subnet, the load balancer and (when built here) the image pipeline."
  type        = string
}

variable "zone" {
  description = "Zone for the NVA and the test VMs."
  type        = string
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to reach the NVA on tcp/22."
  type        = list(string)
}

variable "image" {
  description = "Existing VyOS image (self link, image path or family path). Null builds one with mod-vyos-image."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "NVA machine type."
  type        = string
  default     = "e2-small"
}

variable "vm_machine_type" {
  description = "Test VM machine type."
  type        = string
  default     = "e2-micro"
}

variable "name_prefix" {
  description = "Prefix for every lab resource name."
  type        = string
  default     = "vyos-ncc"
}

variable "center_only_route" {
  description = "Also create a static route in the center VPC only, to show that NCC does not export static routes to the edges."
  type        = bool
  default     = true
}
