variable "enabled" {
  type    = bool
  default = true
}

variable "name" {
  type    = string
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

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "subnets" {
}

variable "peers" {
  type = list(object({
    name          = string
    peer_owner_id = string
    peer_vpc_id   = string
  }))
  default = []
}

variable "vpc_id" {
  type    = string
  default = ""
}
