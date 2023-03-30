# Security Groups
# Control Plane
# Policies
# Service Role

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_security_group" "ClusterSharedNodeSecurityGroup" {
  name = "${var.project_name}-ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-ClusterSharedNodeSecurityGroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "IngressDefaultClusterToNodeSG" {
  security_group_id = aws_security_group.ClusterSharedNodeSecurityGroup.id
  description = "Allow managed and unmanaged nodes to communicate with each other (all ports)"

  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
  referenced_security_group_id = aws_eks_cluster.ControlPlane.vpc_config[0].cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "IngressInterNodeGroupSG" {
  security_group_id = aws_security_group.ClusterSharedNodeSecurityGroup.id
  description = "Allow nodes to communicate with each other (all ports)"

  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
  referenced_security_group_id = aws_security_group.ClusterSharedNodeSecurityGroup.id
}

# I dont know what the purpose of this sg is - I've not seen it populated with any rules
# when generated from eksctl.  The docs say something about 'cross-account elastic network
# interfaces', so maybe this only comes into play with VPC CNI stuff is enabled
resource "aws_security_group" "ControlPlaneSecurityGroup" {
  name = "${var.project_name}-ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-ControlPlaneSecurityGroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "IngressNodeToDefaultClusterSG" {
  security_group_id = aws_eks_cluster.ControlPlane.vpc_config[0].cluster_security_group_id
  description = "Allow unmanaged nodes to communicate with control plane (all ports)"

  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
  referenced_security_group_id = aws_security_group.ClusterSharedNodeSecurityGroup.id
}

resource "aws_iam_role" "ServiceRole" {
  name = "${var.project_name}-ServicesRole"

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
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws-us-gov:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws-us-gov:iam::aws:policy/AmazonEKSVPCResourceController"
  ]

  tags = {
    Name = "${var.project_name}-ServicesRole"
  }
}

resource "aws_iam_role_policy" "PolicyCloudWatchMetrics" {
  name = "${var.project_name}-PolicyCloudWatchMetrics"
  role = aws_iam_role.ServiceRole.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "PolicyELBPermissions" {
  name = "${var.project_name}-PolicyELBPermissions"
  role = aws_iam_role.ServiceRole.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_eks_cluster" "ControlPlane" {
  name = "${var.project_name}"
  role_arn = aws_iam_role.ServiceRole.arn
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access = true
    security_group_ids = [
      aws_security_group.ControlPlaneSecurityGroup.id
    ]
    subnet_ids = var.subnet_ids
  }
  version = "1.25"
  tags = {
    Name = "${var.project_name}-ControlPlane"
  }

}