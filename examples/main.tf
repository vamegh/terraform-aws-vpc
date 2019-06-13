provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = "~> 0.12.1"
}

variable "subnets" {
  //  type  = map(object({}))
  default = {
    private = {
      "availability_zone" = {
        "eu-west-1a" = "10.0.1.0/24"
      }
    }
    database = {
      tags = {
        "description" = "This is description"
      }
      "availability_zone" = {
        "eu-west-1a" = "10.0.10.0/24"
        "eu-west-1b" = "10.0.20.0/24"
        "eu-west-1c" = "10.0.30.0/24"
      }
    }
    test = {
      type = "internal"
      routes = [{
        cidr_block = "8.8.8.0/23"
        peering_id = "pcx-123"
      },
        {
          cidr_block = "1.1.8.0/23"
          dupa_id = "pcx-222"
        }
      ]
      availability_zone = {
        eu-west-1a = "10.1.1.1/24"
      }
    }
    public = {
      "type" = "public"
      "availability_zone" = {
        "eu-west-1a" = "10.0.11.0/24"
        "eu-west-1b" = "10.0.21.0/24"
        "eu-west-1c" = "10.0.31.0/24"
      }
    }
  }
}

locals {
  subnets = flatten([
    for name in keys(var.subnets) : [
      for az in keys(var.subnets[name]["availability_zone"]) : [{
        name       = name
        type       = lookup(var.subnets[name],"type", "private")
        az         = az
        cidr_block = var.subnets[name]["availability_zone"][az]
        route_table = index(keys(var.subnets), name)
        tags = lookup(var.subnets[name], "tags", {})
        routes = lookup(var.subnets[name], "routes", [])
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
}

module "vpc" {
  source                 = "../"

  cidr_block             = "10.0.0.0/16"

  tags = {
    terraform = "true"
    contact = "DevOPS"
    tag1 = "dupa"
  }

  subnets = {
    private = {
      type = "private"
      "availability_zone" = {
        "eu-west-1a" = "10.0.10.0/24"
      }
    }
    intra = {
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
    }
    rds = {
      type = "database"
      "availability_zone" = {
        "eu-west-1a" = "10.0.41.0/24"
        "eu-west-1b" = "10.0.42.0/24"
      }
    }
    public = {
      "type" = "public"
      "availability_zone" = {
        "eu-west-1a" = "10.0.0.0/24"
      }
    }
  }

}


