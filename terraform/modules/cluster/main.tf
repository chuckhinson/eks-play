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
    endpoint_private_access = true
    endpoint_public_access = true
    security_group_ids = [
      var.private_access_security_group_id
    ]
    subnet_ids = var.subnet_ids
  }
  version = "1.25"
  tags = {
    Name = "${var.project_name}-ControlPlane"
  }

}