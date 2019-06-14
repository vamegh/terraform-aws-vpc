provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = "~> 0.12.1"
}

module "vpc" {
  source                 = "../"

  name = "test-vpc"
  cidr_block = "10.0.0.0/16"

  single_nat_gateway = true

  peers = [
    {
      name          = "test-peering"
      peer_vpc_id   = "vpc-123123"
      peer_owner_id = "12341234123"
    }
  ]

  tags = {
    "kubernetes.io/cluster/cluster_name" = "shared"
  }

  subnets = [
    {
      name             = "private"
      type             = "private"

      routes = [
        {
          cidr_block  = "172.16.0.0/24"
          instance_id = "instance-id"
        }
      ]

      tags             = {
        "kubernetes.io/cluster/cluster_name" = "shared"
        "kubernetes.io/role/internal-elb"    = "true"
      }

      availability_zone = {
        "eu-west-1a" = "10.0.1.0/24"
        "eu-west-1b" = "10.0.2.0/24"
        "eu-west-1c" = "10.0.3.0/24"
      }
    },
    {
      name             = "app"
      type             = "private"

      routes = [
        {
          cidr_block = "192.168.0.0/24"
          peering_id = "pcx-123123123"
        }
      ]

      availability_zone = {
        "eu-west-1a" = "10.0.10.0/24"
        "eu-west-1b" = "10.0.20.0/24"
        "eu-west-1c" = "10.0.30.0/24"
      }
    },
    {
      name              = "public"
      type              = "public"
      tags              = {
        "kubernetes.io/cluster/cluster_name" = "shared"
      }
      availability_zone = {
        eu-west-1a = "10.0.4.0/24"
        eu-west-1b = "10.0.5.0/24"
        eu-west-1c = "10.0.6.0/24"
      }
    }
  ]
}


