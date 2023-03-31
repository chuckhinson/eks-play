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

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr_block = var.vpc_cidr_block
  remote_access_cidr_block = var.remote_access_cidr_block
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

module "nodes" {
  source = "./modules/nodes"

  project_name = var.project_name
  subnet_ids = [
    module.vpc.private_subnet1,
    module.vpc.private_subnet2
  ]
  cluster_security_group_id = module.cluster.cluster_security_group_id

}
