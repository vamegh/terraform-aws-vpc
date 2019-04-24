provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = ">= 0.11.11"
}

module "vpc" {
  source = "../"
  cidr = "10.10.0.0/16"
}