terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}


resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = var.project_name
  public_key = tls_private_key.ssh_key.public_key_openssh
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

resource "aws_security_group" "jumpbox" {
  name        = "${var.project_name}-remote"
  description = "Allow remote access to jumpbox"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "ssh from mgmt server"
    protocol         = "tcp"
    from_port        = "22"
    to_port          = "22"
    cidr_blocks      = [var.remote_access_cidr_block]
  }
  # AWS normally provides a default egress rule, but terraform
  # deletes it by default, so we need to add it here to keep it
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = {
    Name = "${var.project_name}-remote"
  }
}

data "aws_ami" "ubuntu_jammy" {
  most_recent      = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  # amazon commercial = 099720109477
  # amazon gov cloud = 513442679011
  owners = ["513442679011"]  # amazon
}

resource "aws_instance" "jumpbox" {
  ami           = data.aws_ami.ubuntu_jammy.id
  associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = "50"
    tags = {
      Name = "${var.project_name}-jumpbox"
      Environment = var.project_name
    }
  }
  instance_type = "t3.micro"
  key_name = aws_key_pair.ec2_keypair.key_name
  private_ip =  cidrhost(aws_subnet.public1.cidr_block,10)
  source_dest_check = false
  subnet_id = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.jumpbox.id]

  tags = {
    Name = "${var.project_name}-jumpbox"
  }
}