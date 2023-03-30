terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile_name
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.project_name
    }
  }  
}

variable "project_name" {
  nullable = false
  description = "The cluster name - will be used in the names of all resources.  This must be the cluster name as provided to kubespray in order for the cloud-controller manager to work properly"
}

variable "aws_profile_name" {
  nullable = false
  description = "That name of the aws profile to be use when access AWS APIs"
}

variable "aws_region" {
  # per https://github.com/hashicorp/terraform-provider-aws/issues/7750 the aws provider is not
  # using the region defined in aws profile, so it will need to be specified
  nullable = false
  description = "The region to operate in"
}

variable "vpc_cidr_block" {
  default = "10.2.0.0/16"
}


module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr_block = var.vpc_cidr_block
}

module "cluster" {
  source = "./modules/cluster"

  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  subnet_ids = [
    module.vpc.public_subnet1,
    module.vpc.public_subnet2,
    module.vpc.private_subnet1,
    module.vpc.private_subnet2
  ]
}

output "project_name" {
  value = var.project_name
}

output "aws_profile_name" {
  value = var.aws_profile_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet1" {
  value = module.vpc.public_subnet1
}

output "public_subnet2" {
  value = module.vpc.public_subnet2
}

output "private_subnet1" {
  value = module.vpc.private_subnet1
}

output "private_subnet2" {
  value = module.vpc.private_subnet2
}


