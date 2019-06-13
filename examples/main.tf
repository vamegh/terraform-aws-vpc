provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = "~> 0.12.1"
}

//variable "peers" {
//  default = {
//    k8s-to-dp = {
//      peer_vpc_id = "vpc-1123"
//      peer_owner_id = "1234567"
//    }
//  }
//}
//
//variable "subnets" {
//  //  type  = map(object({}))
//  default = {
//      private = {
//        tags = {
//          "Secuirty" = "Critical"
//        }
//        "availability_zone" = {
//          "eu-west-1a" = "10.0.10.0/24"
//          "eu-west-1b" = "10.0.11.0/24"
//        }
//      }
//      ursuad = {
//        type = "internal"
//        routes = [
//          {
//            cidr_block = "192.168.0.0/24"
//            peering_id = "pcx-1234123"
//          },
//          {
//            cidr_block = "8.8.8.8/32"
//            instance_id = "instance-idx-123"
//          }
//        ]
//
//        "availability_zone" = {
//          "eu-west-1c" = "10.0.40.0/24"
//        }
//      }
//      rds = {
//        type = "database"
//        "availability_zone" = {
//          "eu-west-1a" = "10.0.41.0/24",
//          "eu-west-1b" = "10.0.42.0/24"
//        }
//      }
//      public = {
//        "type" = "public"
//        "availability_zone" = {
//          "eu-west-1a" = "10.0.0.0/24"
//        }
//      }
//    }
//  }
//
//locals {
//  subnets = flatten([
//    for name in keys(var.subnets) : [
//      for az in keys(var.subnets[name]["availability_zone"]) : [{
//        name       = name
//        type       = lookup(var.subnets[name],"type", "private")
//        az         = az
//        cidr_block = var.subnets[name]["availability_zone"][az]
//        route_table = index(keys(var.subnets), name)
//        tags = lookup(var.subnets[name], "tags", {})
//        routes = lookup(var.subnets[name], "routes", [])
//      }]
//    ]
//  ])
//
//  internal_subnets = flatten([
//    [ for subnet in local.subnets: subnet if subnet.type == "internal" ]
//  ])
//
//  internal_routes = flatten(distinct([
//    for subnet in local.internal_subnets : [
//      subnet["routes"]
//  ] ]))
//
//  route_tables = flatten(distinct([
//    for subnet in local.subnets : [
//      subnet["name"]
//    ]])
//  )
//
//  private_subnets = flatten([
//    [ for subnet in local.subnets: subnet if subnet.type == "private" ]
//  ])
//  public_subnets = flatten([
//    [ for subnet in local.subnets: subnet if subnet.type == "public" ]
//  ])
//  x = flatten([
//     for subnet in local.internal_subnets : [ for route in subnet["routes"]  : route if contains(keys(route), "peering_id")  ]
//  ])
//
//  peers = flatten([
//  for name in keys(var.peers) : [{
//    name = name
//    peer_vpc_id = var.peers[name].peer_vpc_id
//    peer_owner_id = var.peers[name].peer_owner_id
//    peer_region = lookup(var.peers[name], "peer_region", "eu-west-1")
//  }]])
//}

module "vpc" {
  source                 = "../"

  cidr_block             = "10.0.0.0/16"

  tags = {
    terraform = "true"
    contact = "DevOPS"
    tag1 = "dupa"
  }

  peers = {
    testpeering = {
      peer_vpc_id = "vpc-1123"
      peer_owner_id = "1234567"
    }
  }

  subnets = {
    private = {
      tags = {
        "Secuirty" = "Critical"
      }
      "availability_zone" = {
        "eu-west-1a" = "10.0.10.0/24"
        "eu-west-1b" = "10.0.11.0/24"
      }
    }
    internalonly = {
      type = "internal"
      routes = [{
        cidr_block = "192.168.0.0/24"
        peering_id = "pcx-1234123"
      }, {
        cidr_block = "8.8.8.8/32"
        instance_id = "instance-idx-123"
      }]

      "availability_zone" = {
        "eu-west-1c" = "10.0.40.0/24"
      }
    }
    rds = {
      type = "database"
      "availability_zone" = {
        "eu-west-1a" = "10.0.41.0/24",
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


