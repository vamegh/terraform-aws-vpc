terraform {
  required_version = "~> 0.12.1"
}

locals {
  subnets = flatten([
    for name in keys(var.subnets) : [
      for az in keys(var.subnets[name]["availability_zone"]) : [{
        name                    = name
        az                      = az
        cidr_block              = var.subnets[name]["availability_zone"][az]
        route_table_idx         = index(keys(var.subnets), name)
        type                    = lookup(var.subnets[name], "type", "private")
        tags                    = lookup(var.subnets[name], "tags", {})
        map_public_ip_on_launch = lookup(var.subnets[name], "map_public_ip_on_launch", "false")
        routes                  = lookup(var.subnets[name], "routes", [])
      }]
    ]
  ])

  public_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "public" ]
  ])

  private_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "private" ]
  ])

  internal_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "internal" ]
  ])

  database_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "database" ]
  ])

  redshift_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "redshift" ]
  ])

  route_tables = flatten(distinct([
    for subnet in local.subnets :
      subnet["name"]
   ]))


  tags = merge(var.tags, {
    "name" = var.name
  })
}

# VPC configuration
resource "aws_vpc" "main" {
  count = var.enabled ? 1 : 0

  cidr_block                     = cidrsubnet(var.cidr_block, 0, 0)
  instance_tenancy               = var.instance_tenancy
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support
  tags                           = local.tags
}

resource "aws_vpc_ipv4_cidr_block_association" "main" {
  count = var.enabled && length(var.secondary_cidr) > 0 ? length(var.secondary_cidr) : 0

  vpc_id     = aws_vpc.main[0].id
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
  tags                 = local.tags
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = var.enabled && var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.main[0].id
  dhcp_options_id = aws_vpc_dhcp_options.main[count.index].id
}

# Netowrk configuration

resource "aws_internet_gateway" "main" {
  count = var.enabled ? 1 : 0

  vpc_id = aws_vpc.main[0].id
  tags = local.tags
}

resource "aws_eip" "main" {
  count         = var.enabled && length(local.public_subnets) > 0  ? length(local.public_subnets) : 0

  vpc = true
}

resource "aws_nat_gateway" "main" {
  count         = var.enabled && length(local.public_subnets) > 0  ? length(local.public_subnets) : 0

  allocation_id = aws_eip.main[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_route_table" "public" {
  count = var.enabled && length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

   dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "gateway_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "instance_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      instance_id = route.value.instance_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = local.tags
}

resource "aws_subnet" "public" {
  count                   = var.enabled && length(local.public_subnets) > 0 ? length(local.public_subnets) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(local.public_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.public_subnets[count.index].az
  map_public_ip_on_launch = local.public_subnets[count.index].map_public_ip_on_launch
  tags = merge(merge(local.tags,
    map(
      "subnet", local.public_subnets[count.index].name,
      "cidr_block", local.public_subnets[count.index].cidr_block,
      "availability_zone", local.public_subnets[count.index].az,
      "type", local.public_subnets[count.index].type
    )
  ), local.public_subnets[count.index].tags)
}


resource "aws_route_table_association" "public" {
  count          = var.enabled && length(local.public_subnets) > 0 ? length(local.public_subnets) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count  = var.enabled && length(local.private_subnets) > 0 ? length(local.public_subnets) : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "instance_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      instance_id = route.value.instance_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }


  tags = local.tags
}

resource "aws_subnet" "private" {
  count                   = var.enabled && length(local.private_subnets) > 0 ? length(local.private_subnets) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(local.private_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.private_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    map(
      "subnet", local.private_subnets[count.index].name,
      "cidr_block", local.private_subnets[count.index].cidr_block,
      "availability_zone", local.private_subnets[count.index].az,
      "type", local.private_subnets[count.index].type
    )
  ), local.private_subnets[count.index].tags)
}

resource "aws_route_table_association" "private" {
  count  = var.enabled && length(local.private_subnets) > 0 ? length(local.private_subnets) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table" "internal" {
  count  = var.enabled && length(local.internal_subnets) > 0 ? length(local.internal_subnets) : 0

  vpc_id = aws_vpc.main[0].id

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "instance_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      instance_id = route.value.instance_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = local.tags
}

resource "aws_subnet" "internal" {
  count                   = var.enabled && length(local.internal_subnets) > 0 ? length(local.internal_subnets) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(local.internal_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.internal_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    map(
      "subnet", local.internal_subnets[count.index].name,
      "cidr_block", local.internal_subnets[count.index].cidr_block,
      "availability_zone", local.internal_subnets[count.index].az,
      "type", local.internal_subnets[count.index].type
    )
  ), local.internal_subnets[count.index].tags)
}

resource "aws_route_table_association" "internal" {
  count  = var.enabled && length(local.internal_subnets) > 0 ? length(local.internal_subnets) : 0

  subnet_id      = aws_subnet.internal[count.index].id
  route_table_id = aws_route_table.internal[0].id
}

resource "aws_route_table" "database" {
  count  = var.enabled && length(local.database_subnets) > 0 ? length(local.public_subnets) : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "instance_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      instance_id = route.value.instance_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = local.tags
}

resource "aws_subnet" "database" {
  count                   = var.enabled && length(local.database_subnets) > 0 ? length(local.database_subnets) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(local.database_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.database_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    map(
      "subnet", local.database_subnets[count.index].name,
      "cidr_block", local.database_subnets[count.index].cidr_block,
      "availability_zone", local.database_subnets[count.index].az,
      "type", local.database_subnets[count.index].type
    )
  ), local.database_subnets[count.index].tags)
}

resource "aws_route_table_association" "database" {
  count  = var.enabled && length(local.database_subnets) > 0 ? length(local.database_subnets) : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_db_subnet_group" "database" {
  count = var.enabled && length(local.database_subnets) > 0  ? 1 : 0

  name        = lower(var.name)
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database.*.id

  tags = local.tags
}

resource "aws_route_table" "redshift" {
  count  = var.enabled && length(local.redshift_subnets) > 0 ? length(local.public_subnets) : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "instance_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      instance_id = route.value.instance_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"]  :
          route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = local.tags
}

resource "aws_subnet" "redshift" {
  count                   = var.enabled && length(local.redshift_subnets) > 0 ? length(local.redshift_subnets) : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(local.redshift_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.redshift_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    map(
      "subnet", local.redshift_subnets[count.index].name,
      "cidr_block", local.redshift_subnets[count.index].cidr_block,
      "availability_zone", local.redshift_subnets[count.index].az,
      "type", local.redshift_subnets[count.index].type
    )
  ), local.redshift_subnets[count.index].tags)
}

resource "aws_route_table_association" "redshift" {
  count  = var.enabled && length(local.redshift_subnets) > 0 ? length(local.redshift_subnets) : 0

  subnet_id      = aws_subnet.redshift[count.index].id
  route_table_id = aws_route_table.redshift[0].id
}

resource "aws_redshift_subnet_group" "redshift" {
  count = var.enabled && length(local.redshift_subnets) > 0  ? 1 : 0

  name        = lower(var.name)
  description = "Redshift subnet group for ${var.name}"
  subnet_ids  = aws_subnet.redshift.*.id

  tags = local.tags
}
