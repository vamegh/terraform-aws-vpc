variable "enabled" {
  type = "string"
  default = "true"
}

variable "cidr" {
  type = "string"
}

variable "secondary_cidr" {
  type = "list"
  default = []
}

variable "tags" {
  type = "map"
  default = {}
}

variable "instance_tenancy" {
  type = "string"
  default = "default"
}

variable "enable_dns_support" {
  type = "string"
  default = "true"
}

variable "enable_dns_hostnames" {
  type = "string"
  default = "false"
}

variable "enable_classiclink" {
  type = "string"
  default = "false"
}

variable "enable_classiclink_dns_support" {
  type = "string"
  default = "false"
}

variable "enable_dhcp_options" {
  type = "string"
  default = "false"
}

variable "dhcp_options_domain_name" {
  type = "string"
  default = "false"
}

variable "dhcp_options_domain_name_servers" {
  type = "list"
  default = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  type = "list"
  default = []
}

variable "dhcp_options_netbios_name_servers" {
  type    = "list"
  default = []
}

variable "dhcp_options_netbios_node_type" {
  description = "Specify netbios node_type for DHCP options set"
  default     = ""
}
