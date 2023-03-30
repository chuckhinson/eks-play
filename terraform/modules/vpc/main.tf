terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.project_name
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = var.project_name
  }
}

resource "aws_eip" "main" {
  vpc = true
  tags = {
    Name = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public"
  }
}

resource "aws_route" "public-external" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private"
  }
}

resource "aws_route" "private-nat-gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}


resource "aws_subnet" "public1" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block,8,1)
  availability_zone = "us-gov-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block,8,3)
  availability_zone = "us-gov-west-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public2"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private1" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block,8,2)
  availability_zone = "us-gov-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-private1"
    "kubernetes.io/role/internal-elb" = "1"
    # # Terraform nodegroup docs say the following tag is necessary, but eksctl didnt tag the subnets with it
    # "kubernetes.io/cluster/${var.project_name}" = ""
  }
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block,8,4)
  availability_zone = "us-gov-west-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-private2"
    "kubernetes.io/role/internal-elb" = "1"
    # # Terraform nodegroup docs say the following tag is necessary, but eksctl didnt tag the subnets with it
    # "kubernetes.io/cluster/${var.project_name}" = ""
  }
}

