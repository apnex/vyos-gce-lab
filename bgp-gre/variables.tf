variable "project_id" {
  description = "Project for the lab."
  type        = string
}

variable "region" {
  description = "Region for the lab networks (and the image pipeline, when it is built here)."
  type        = string
}

variable "zone" {
  description = "Zone for the routers."
  type        = string
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to reach the routers' management interfaces on tcp/22."
  type        = list(string)
}

variable "image" {
  description = "Existing VyOS image (self link, image path or family path). Null builds one with mod-vyos-image."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Router machine type; 2 vCPUs allow the two interfaces this topology uses."
  type        = string
  default     = "e2-small"
}

variable "name_prefix" {
  description = "Prefix for every lab resource name."
  type        = string
  default     = "vyos-lab"
}
