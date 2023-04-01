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

data "aws_instance" "jumpbox" {
  instance_id = module.vpc.jumpbox_instance_id
}

resource "aws_security_group" "control_plane_private_access" {
  name = "${var.project_name}-control_plane_private_access"
  description = "All control plane to receive requests from jumpbox"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-control_plane_private_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_jumpbox_to_private_endpoint" {
  security_group_id = aws_security_group.control_plane_private_access.id
  description = "Allow jumpbox to access private control plan endpoint"

  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
  cidr_ipv4 = "${data.aws_instance.jumpbox.private_ip}/32"
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
  private_access_security_group_id = aws_security_group.control_plane_private_access.id
}

module "nodes" {
  source = "./modules/nodes"

  project_name = var.project_name
  subnet_ids = [
    module.vpc.private_subnet1,
    module.vpc.private_subnet2
  ]
  cluster_security_group_id = module.cluster.cluster_security_group_id
  remote_ssh_cdir_block = "${data.aws_instance.jumpbox.private_ip}/32"
  node_keypair_name = module.vpc.ssh_keypair_name
}
