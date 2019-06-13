variable "enabled" {
  type    = bool
  default = true
}

variable "name" {
  type = string
  default = "main-vpc"
}

variable "cidr_block" {
  type = string
}

variable "secondary_cidr" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "instance_tenancy" {
  type    = string
  default = "default"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = false
}

variable enable_classiclink {
  type    = bool
  default = false
}

variable "enable_classiclink_dns_support" {
  type    = bool
  default = false
}

variable "enable_dhcp_options" {
  type    = bool
  default = false
}

variable "dhcp_options_domain_name" {
  type    = bool
  default = false
}

variable "dhcp_options_domain_name_servers" {
  type    = list(string)
  default = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  type    = list(string)
  default = []
}

variable "dhcp_options_netbios_name_servers" {
  type    = list(string)
  default = []
}

variable "dhcp_options_netbios_node_type" {
  type        = string
  description = "Specify netbios node_type for DHCP options set"
  default     = ""
}

variable "subnets" {
}

variable "peers" {
}

