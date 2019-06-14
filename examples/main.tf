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

  tags = {
    "kubernetes.io/cluster/cluster_name" = "shared"
  }

  subnets = [
    {
      name             = "private"
      type             = "private"
      tags             = {
        "kubernetes.io/cluster/local.cluster_name" = "shared"
        "kubernetes.io/role/internal-elb"          = "true"
      }
      availability_zone = {
        "eu-west-1a" = "10.0.1.0/24"
        "eu-west-1b" = "10.0.2.0/24"
        "eu-west-1c" = "10.0.3.0/24"
      }
    },
    {
      name              = "public"
      type              = "public"
      tags              = {
        "kubernetes.io/cluster/local.cluster_name" = "shared"
      }
      availability_zone = {
        eu-west-1a = "10.0.4.0/24"
        eu-west-1b = "10.0.5.0/24"
        eu-west-1c = "10.0.6.0/24"
      }
    }
  ]
}


