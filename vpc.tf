# VPC configuration
resource "aws_vpc" "main" {
  count = var.enabled && var.vpc_id == "" ? 1 : 0

  cidr_block           = cidrsubnet(var.cidr_block, 0, 0)
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = merge(
    local.tags,
    {
      "Name" = local.vpc_name
    }
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "main" {
  count = var.enabled && length(var.secondary_cidr) > 0 ? length(var.secondary_cidr) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.secondary_cidr[count.index]
}

# VPC DHCP settings
resource "aws_vpc_dhcp_options" "main" {
  count = var.enabled && var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type
  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = var.enabled && var.enable_dhcp_options ? 1 : 0

  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.main[count.index].id
}

resource "aws_vpc_peering_connection" "main" {
  count         = var.enabled && length(local.peers) > 0 ? length(local.peers) : 0
  vpc_id        = local.vpc_id
  peer_vpc_id   = local.peers[count.index].peer_vpc_id
  peer_owner_id = local.peers[count.index].peer_owner_id
  peer_region   = local.peers[count.index].peer_region
  auto_accept   = false

  tags = merge(local.tags,
    {
      "Name" = local.peers[count.index].name
    }
  )
}

