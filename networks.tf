# Network configuration
resource "aws_internet_gateway" "main" {
  count = var.enabled ? 1 : 0

  vpc_id = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-igw"
    }
  )
}

resource "aws_eip" "main" {
  count = var.enabled && length(local.public_subnets) > 0 ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count = var.enabled && length(local.public_subnets) > 0 ? local.nat_gateway_count : 0

  allocation_id = aws_eip.main[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-nat-gw"
    }
  )
}

resource "aws_route_table" "public" {
  count  = var.enabled && length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.public_subnets : [
        for route in subnet["routes"] :
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
      for subnet in local.public_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "network_interface_id")
      ]
    ])

    content {
      cidr_block  = route.value.cidr_block
      network_interface_id = route.value.network_interface_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.public_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block                = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-route-table-public"
    }
  )
}

resource "aws_subnet" "public" {
  count = var.enabled && length(local.public_subnets) > 0 ? length(local.public_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(local.public_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.public_subnets[count.index].az
  map_public_ip_on_launch = local.public_subnets[count.index].map_public_ip_on_launch
  tags = merge(merge(local.tags,
    {
      "Name"              = format("%s-subnet-%s-%s", var.name, local.public_subnets[count.index].type, local.public_subnets[count.index].az),
      "Subnet"            = local.public_subnets[count.index].name,
      "Cidr_block"        = local.public_subnets[count.index].cidr_block,
      "Availability_zone" = local.public_subnets[count.index].az,
      "Type"              = local.public_subnets[count.index].type
    }
  ), local.public_subnets[count.index].tags)
}


resource "aws_route_table_association" "public" {
  count = var.enabled && length(local.public_subnets) > 0 ? length(local.public_subnets) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = var.enabled && length(local.private_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id


  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.private_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block     = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.private_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "network_interface_id")
      ]
    ])

    content {
      cidr_block  = route.value.cidr_block
      network_interface_id = route.value.network_interface_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.private_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block                = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-route-table-private"
    }
  )
}

resource "aws_subnet" "private" {
  count = var.enabled && length(local.private_subnets) > 0 ? length(local.private_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(local.private_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.private_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    {
      "Name"              = format("%s-subnet-%s-%s", var.name, local.private_subnets[count.index].type, local.private_subnets[count.index].az),
      "Subnet"            = local.private_subnets[count.index].name,
      "Cidr_block"        = local.private_subnets[count.index].cidr_block,
      "Availability_zone" = local.private_subnets[count.index].az,
      "Type"              = local.private_subnets[count.index].type
    }
  ), local.private_subnets[count.index].tags)
}

resource "aws_route_table_association" "private" {
  count = var.enabled && length(local.private_subnets) > 0 ? length(local.private_subnets) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table" "internal" {
  count = var.enabled && length(local.internal_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block     = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "network_interface_id")
      ]
    ])

    content {
      cidr_block  = route.value.cidr_block
      network_interface_id = route.value.network_interface_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.internal_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block                = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-route-table-internal"
    }
  )
}

resource "aws_subnet" "internal" {
  count = var.enabled && length(local.internal_subnets) > 0 ? length(local.internal_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(local.internal_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.internal_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    {
      "Name"              = format("%s-subnet-%s-%s", var.name, local.internal_subnets[count.index].type, local.internal_subnets[count.index].az),
      "Subnet"            = local.internal_subnets[count.index].name,
      "Cidr_block"        = local.internal_subnets[count.index].cidr_block,
      "Availability_zone" = local.internal_subnets[count.index].az,
      "Type"              = local.internal_subnets[count.index].type
    }
  ), local.internal_subnets[count.index].tags)
}

resource "aws_route_table_association" "internal" {
  count = var.enabled && length(local.internal_subnets) > 0 ? length(local.internal_subnets) : 0

  subnet_id      = aws_subnet.internal[count.index].id
  route_table_id = aws_route_table.internal[0].id
}

resource "aws_route_table" "database" {
  count = var.enabled && length(local.database_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.database_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block     = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.database_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "network_interface_id")
      ]
    ])

    content {
      cidr_block  = route.value.cidr_block
      network_interface_id = route.value.network_interface_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.database_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block                = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-route-table-database"
    }
  )
}

resource "aws_subnet" "database" {
  count = var.enabled && length(local.database_subnets) > 0 ? length(local.database_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(local.database_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.database_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    {
      "Name"              = format("%s-subnet-%s-%s", var.name, local.database_subnets[count.index].type, local.database_subnets[count.index].az),
      "Subnet"            = local.database_subnets[count.index].name,
      "Cidr_block"        = local.database_subnets[count.index].cidr_block,
      "Availability_zone" = local.database_subnets[count.index].az,
      "Type"              = local.database_subnets[count.index].type
    }
  ), local.database_subnets[count.index].tags)
}

resource "aws_route_table_association" "database" {
  count = var.enabled && length(local.database_subnets) > 0 ? length(local.database_subnets) : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_db_subnet_group" "database" {
  count = var.enabled && length(local.database_subnets) > 0 ? 1 : 0

  name        = lower(var.name)
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database.*.id

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-db-subnet-group-database"
    }
  )
}

resource "aws_route_table" "redshift" {
  count = var.enabled && length(local.redshift_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.redshift_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "nat_gateway_id")
      ]
    ])

    content {
      cidr_block     = route.value.cidr_block
      nat_gateway_id = route.value.nat_gateway_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.redshift_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "network_interface_id")
      ]
    ])

    content {
      cidr_block  = route.value.cidr_block
      network_interface_id = route.value.network_interface_id
    }
  }

  dynamic "route" {
    for_each = flatten([
      for subnet in local.redshift_subnets : [
        for route in subnet["routes"] :
        route if contains(keys(route), "peering_id")
      ]
    ])

    content {
      cidr_block                = route.value.cidr_block
      vpc_peering_connection_id = route.value.peering_id
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-route-table-redshift"
    }
  )
}

resource "aws_subnet" "redshift" {
  count = var.enabled && length(local.redshift_subnets) > 0 ? length(local.redshift_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(local.redshift_subnets[count.index].cidr_block, 0, 0)
  availability_zone       = local.redshift_subnets[count.index].az
  map_public_ip_on_launch = false
  tags = merge(merge(local.tags,
    {
      "Name"              = format("%s-subnet-%s-%s", var.name, local.redshift_subnets[count.index].type, local.redshift_subnets[count.index].az),
      "Subnet"            = local.redshift_subnets[count.index].name,
      "Cidr_block"        = local.redshift_subnets[count.index].cidr_block,
      "Availability_zone" = local.redshift_subnets[count.index].az,
      "Type"              = local.redshift_subnets[count.index].type
    }
  ), local.redshift_subnets[count.index].tags)
}

resource "aws_route_table_association" "redshift" {
  count = var.enabled && length(local.redshift_subnets) > 0 ? length(local.redshift_subnets) : 0

  subnet_id      = aws_subnet.redshift[count.index].id
  route_table_id = aws_route_table.redshift[0].id
}

resource "aws_redshift_subnet_group" "redshift" {
  count = var.enabled && length(local.redshift_subnets) > 0 ? 1 : 0

  name        = lower(var.name)
  description = "Redshift subnet group for ${var.name}"
  subnet_ids  = aws_subnet.redshift.*.id

  tags = merge(
    local.tags,
    {
      "Name" = "${var.name}-db-subnet-group-redshift"
    }
  )
}
