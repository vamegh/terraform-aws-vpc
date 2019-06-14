provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = "~> 0.12.1"
}

variable "peers" {
  default = [
    {
      name = "x-to-y"
      peer_vpc_id = "vpc-1123"
      peer_owner_id = "1234567"
    }
  ]
}

variable "subnets" {
  //  type  = map(object({}))
  default = [
      {
        name = "private"
        type = "private"
        tags = {
          "Secuirty" = "Critical"
        }
        "availability_zone" = {
          "eu-west-1a" = "10.0.10.0/24"
          "eu-west-1b" = "10.0.11.0/24"
        }
      },
      {
        name = "internalonly"
        type = "internal"
        routes = [
          {
            cidr_block = "192.168.0.0/24"
            peering_id = "pcx-1234123"
          },
          {
            cidr_block = "8.8.8.8/32"
            instance_id = "instance-idx-123"
          }
        ]

        "availability_zone" = {
          "eu-west-1c" = "10.0.40.0/24"
        }
      },
      {
        name = "rds"
        type = "database"
        "availability_zone" = {
          "eu-west-1a" = "10.0.41.0/24",
          "eu-west-1b" = "10.0.42.0/24"
        }
      },
      {
        name = "public"
        "type" = "public"
        "availability_zone" = {
          "eu-west-1a" = "10.0.0.0/24"
        }
      }
    ]
  }

locals {
  subnets = flatten([
    for subnet in var.subnets : [
      for az in keys(subnet["availability_zone"]) : [{
        name       = subnet["name"]
        type       = lookup(subnet,"type", "private")
        az         = az
        cidr_block = subnet["availability_zone"][az]
        tags = lookup(subnet, "tags", {})
        routes = lookup(subnet, "routes", [])
      }]
    ]
  ])

  internal_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "internal" ]
  ])

  internal_routes = flatten(distinct([
    for subnet in local.internal_subnets : [
      subnet["routes"]
  ] ]))

  route_tables = flatten(distinct([
    for subnet in local.subnets : [
      subnet["name"]
    ]])
  )

  private_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "private" ]
  ])
  public_subnets = flatten([
    [ for subnet in local.subnets: subnet if subnet.type == "public" ]
  ])
  x = flatten([
     for subnet in local.internal_subnets : [ for route in subnet["routes"]  : route if contains(keys(route), "peering_id")  ]
  ])

  peers = flatten([
  for peer in var.peers : [{
    name = peer.name
    peer_vpc_id = peer.peer_vpc_id
    peer_owner_id = peer.peer_owner_id
    peer_region = lookup(peer, "peer_region", "eu-west-1")
  }]])
}

module "vpc" {
  source                 = "../"

  cidr_block             = "10.0.0.0/16"

  tags = {
    terraform = "true"
    contact = "DevOPS"
    tag1 = "dupa"
  }

  peers = [
    {
      name = "x-to-y"
      peer_vpc_id = "vpc-123"
      peer_owner_id = "123456"
    }
  ]

  subnets = [
    {
      name = "private"
      tags = {
        "Secuirty" = "Critical"
      }
      "availability_zone" = {
        "eu-west-1a" = "10.0.10.0/24"
        "eu-west-1b" = "10.0.11.0/24"
      }
    },
    {
      name = "public"
      "type" = "public"
      "availability_zone" = {
        "eu-west-1a" = "10.0.0.0/24"
      }
    }
  ]

}


