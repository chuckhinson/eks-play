terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_partition" "current" {}

resource "aws_iam_role" "NodeInstanceRole" {
  name = "${var.project_name}-NodeInstanceRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  path = "/"

  tags = {
    Name = "${var.project_name}-NodeInstanceRole"
  }
}

locals {
  # Need to do this to prevent cycle between ManagedNodeGroup and LaunchTemplate
  managed_node_group_name = "${var.project_name}-ManagedNodeGroup"
}

resource "aws_eks_node_group" "ManagedNodeGroup" {
  node_group_name = local.managed_node_group_name

  ami_type = "AL2_x86_64"
  cluster_name = "${var.project_name}"
  instance_types = [
    "m5.large"
  ]
  labels = {
    "alpha.eksctl.io/cluster-name" = "k8schuckm",
    "alpha.eksctl.io/nodegroup-name" = "ng-35a31705"
  }
  launch_template {
    id = aws_launch_template.LaunchTemplate.id
    version = aws_launch_template.LaunchTemplate.default_version
  }
  node_role_arn = aws_iam_role.NodeInstanceRole.arn
  scaling_config {
    desired_size = 2
    max_size = 2
    min_size = 2
  }
  subnet_ids = var.subnet_ids
  tags = {
    Name = "${var.project_name}-NodeInstanceRole"
    "alpha.eksctl.io/nodegroup-name" = local.managed_node_group_name,
    "alpha.eksctl.io/nodegroup-type" = "managed"
  }

}

resource "aws_launch_template" "LaunchTemplate" {
  name = "${var.project_name}-LaunchTemplate"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      iops = 3000
      throughput = 125
      volume_size = 80
      volume_type = "gp3"
    }
  }
  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens = "optional"
  }
  key_name = var.node_keypair_name
  vpc_security_group_ids = [var.cluster_security_group_id, aws_security_group.remote_access.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${var.project_name}-${local.managed_node_group_name}-Node"
      "alpha.eksctl.io/nodegroup-name" = local.managed_node_group_name
      "alpha.eksctl.io/nodegroup-type" = "managed"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "${var.project_name}-${local.managed_node_group_name}-Node"
      "alpha.eksctl.io/nodegroup-name" = local.managed_node_group_name
      "alpha.eksctl.io/nodegroup-type" = "managed"
    }
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = {
      "Name" = "${var.project_name}-${local.managed_node_group_name}-Node"
      "alpha.eksctl.io/nodegroup-name" = local.managed_node_group_name
      "alpha.eksctl.io/nodegroup-type" = "managed"
    }
  }
}


data "aws_subnet" "public_subnet1" {
  id = var.subnet_ids[0]
}

resource "aws_security_group" "remote_access" {
  name = "${var.project_name}-remote-access"
  description = "allow ssh from remote CIDR block"
  vpc_id = data.aws_subnet.public_subnet1.vpc_id

  tags = {
    Name = "${var.project_name}-remote_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_remote_cidr_block" {
  security_group_id = aws_security_group.remote_access.id
  description = "Allow ssh access from remote cidr block"

  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
  cidr_ipv4 = var.remote_ssh_cdir_block
}
