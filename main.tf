provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = ">= 0.11.11"
}

locals {
  enabled                          = "${var.enabled == "true" ? true : false}"
  enable_dns_support               = "${var.enable_dns_support == "true" ? true : false}"
  enable_dns_hostnames             = "${var.enable_dns_hostnames == "true" ? true : false}"
  enable_classiclink               = "${var.enable_classiclink == "true" ? true : false}"
  enable_classiclink_dns_support   = "${var.enable_classiclink_dns_support == "true" ? true : false}"
  enable_dhcp_options              = "${var.enable_dhcp_options == "true" ? true : false}"
}

# VPC configuration
resource "aws_vpc" "main" {
  count                           = "${local.enabled ? 1 : 0}"

  cidr_block                      = "${var.cidr}"
  instance_tenancy                = "${var.instance_tenancy}"
  enable_dns_support              = "${local.enable_dns_support}"
  enable_dns_hostnames            = "${local.enable_dns_hostnames}"
  enable_classiclink              = "${local.enable_classiclink}"
  enable_classiclink_dns_support  = "${local.enable_classiclink_dns_support}"
  tags                            = "${var.tags}"
}

resource "aws_vpc_ipv4_cidr_block_association" "main" {
  count       = "${local.enabled && length(var.secondary_cidr) > 0 ? length(var.secondary_cidr) : 0}"

  vpc_id      = "${aws_vpc.main.id}"
  cidr_block  = "${element(var.secondary_cidr, count.index)}"
}

# VPC DHCP settings
resource "aws_vpc_dhcp_options" "main" {
  count                 = "${local.enabled && local.enable_dhcp_options ? 1 : 0}"

  domain_name           = "${var.dhcp_options_domain_name}"
  domain_name_servers   = "${var.dhcp_options_domain_name_servers}"
  ntp_servers           = "${var.dhcp_options_ntp_servers}"
  netbios_name_servers  = "${var.dhcp_options_netbios_name_servers}"
  netbios_node_type     = "${var.dhcp_options_netbios_node_type}"
  tags                  = "${var.tags}"
}

resource "aws_vpc_dhcp_options_association" "main" {
  count           = "${local.enabled && local.enable_dhcp_options ? 1 : 0}"

  vpc_id          = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
}

