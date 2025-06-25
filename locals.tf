locals {
  vpc_name = "${var.name}-vpc"
  subnets = flatten([
    for subnet in var.subnets : [
      for az in keys(subnet["availability_zone"]) : [{
        name                    = subnet["name"]
        type                    = lookup(subnet, "type", "private")
        az                      = az
        cidr_block              = subnet["availability_zone"][az]
        map_public_ip_on_launch = lookup(subnet, "map_public_ip_on_launch", "false")
        tags                    = lookup(subnet, "tags", {})
        routes                  = lookup(subnet, "routes", [])
      }]
    ]
  ])

  public_subnets = flatten([
    [for subnet in local.subnets : subnet if subnet.type == "public"]
  ])

  private_subnets = flatten([
    [for subnet in local.subnets : subnet if subnet.type == "private"]
  ])

  internal_subnets = flatten([
    [for subnet in local.subnets : subnet if subnet.type == "internal"]
  ])

  database_subnets = flatten([
    [for subnet in local.subnets : subnet if subnet.type == "database"]
  ])

  redshift_subnets = flatten([
    [for subnet in local.subnets : subnet if subnet.type == "redshift"]
  ])

  route_tables = flatten(distinct([
    for subnet in local.subnets :
    subnet["name"]
  ]))

  peers = flatten([
    for peer in var.peers : [{
      name          = peer.name
      peer_vpc_id   = peer.peer_vpc_id
      peer_owner_id = peer.peer_owner_id
      peer_region   = lookup(peer, "peer_region", "eu-west-1")
    }]
  ])

  nat_gateway_count = var.single_nat_gateway ? 1 : length(local.public_subnets)
  vpc_id            = var.vpc_id != "" ? var.vpc_id : aws_vpc.main[0].id

  tags = merge(
    var.tags,
    {
      "Vpc" = local.vpc_name
  })

}
