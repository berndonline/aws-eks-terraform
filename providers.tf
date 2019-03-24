provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "techbloc-terraform-data"
    key    = "openshift-311"
    region = "eu-west-1"
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
