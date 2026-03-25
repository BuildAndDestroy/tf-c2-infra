terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
}

# -----------------------------
# VPC A (single instance)
# -----------------------------
resource "aws_vpc" "vpc_a" {
  cidr_block           = var.vpc_a_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-a"
  }
}

resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "${var.project_name}-igw-a"
  }
}

resource "aws_subnet" "subnet_a_public" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = var.subnet_a_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-a-public"
  }
}

resource "aws_route_table" "rt_a_public" {
  vpc_id = aws_vpc.vpc_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_a.id
  }

  tags = {
    Name = "${var.project_name}-rt-a-public"
  }
}

resource "aws_route_table_association" "rt_assoc_a_public" {
  subnet_id      = aws_subnet.subnet_a_public.id
  route_table_id = aws_route_table.rt_a_public.id
}

resource "aws_security_group" "sg_a" {
  name        = "${var.project_name}-sg-a"
  description = "VPC A SG: SSH from internet, all from VPC B"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All traffic from VPC B"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_b_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-a"
  }
}

resource "aws_network_interface" "eni_a" {
  subnet_id       = aws_subnet.subnet_a_public.id
  private_ips     = [var.instance_a_private_ip]
  security_groups = [aws_security_group.sg_a.id]

  tags = {
    Name = "${var.project_name}-eni-a"
  }
}

resource "aws_instance" "instance_a" {
  ami           = local.ami_id
  instance_type = var.instance_type_a
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.eni_a.id
    device_index         = 0
  }

  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOT
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              EOT

  tags = {
    Name = "${var.project_name}-instance-a"
    Role = "docker-host"
  }
}

resource "aws_eip" "eip_a" {
  domain            = "vpc"
  network_interface = aws_network_interface.eni_a.id
  depends_on        = [aws_internet_gateway.igw_a]

  tags = {
    Name = "${var.project_name}-eip-a"
  }
}

# -----------------------------
# VPC B (two instances)
# -----------------------------
resource "aws_vpc" "vpc_b" {
  cidr_block           = var.vpc_b_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-b"
  }
}

resource "aws_internet_gateway" "igw_b" {
  vpc_id = aws_vpc.vpc_b.id

  tags = {
    Name = "${var.project_name}-igw-b"
  }
}

resource "aws_subnet" "subnet_b_public_1" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = var.subnet_b1_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-b-public-1"
  }
}

resource "aws_subnet" "subnet_b_public_2" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = var.subnet_b2_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-b-public-2"
  }
}

resource "aws_route_table" "rt_b_public" {
  vpc_id = aws_vpc.vpc_b.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_b.id
  }

  tags = {
    Name = "${var.project_name}-rt-b-public"
  }
}

resource "aws_route_table_association" "rt_assoc_b_public_1" {
  subnet_id      = aws_subnet.subnet_b_public_1.id
  route_table_id = aws_route_table.rt_b_public.id
}

resource "aws_route_table_association" "rt_assoc_b_public_2" {
  subnet_id      = aws_subnet.subnet_b_public_2.id
  route_table_id = aws_route_table.rt_b_public.id
}

resource "aws_security_group" "sg_b" {
  name        = "${var.project_name}-sg-b"
  description = "VPC B SG: SSH/HTTPS from internet, all from VPC A"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All traffic from VPC A"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_a_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-b"
  }
}

resource "aws_network_interface" "eni_b1" {
  subnet_id       = aws_subnet.subnet_b_public_1.id
  private_ips     = [var.instance_b1_private_ip]
  security_groups = [aws_security_group.sg_b.id]

  tags = {
    Name = "${var.project_name}-eni-b1"
  }
}

resource "aws_network_interface" "eni_b2" {
  subnet_id       = aws_subnet.subnet_b_public_2.id
  private_ips     = [var.instance_b2_private_ip]
  security_groups = [aws_security_group.sg_b.id]

  tags = {
    Name = "${var.project_name}-eni-b2"
  }
}

resource "aws_instance" "instance_b1" {
  ami           = local.ami_id
  instance_type = var.instance_type_b
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.eni_b1.id
    device_index         = 0
  }

  user_data = <<-EOT
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              EOT

  tags = {
    Name = "${var.project_name}-instance-b1"
    Role = "docker-host"
  }
}

resource "aws_instance" "instance_b2" {
  ami           = local.ami_id
  instance_type = var.instance_type_b
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.eni_b2.id
    device_index         = 0
  }

  user_data = <<-EOT
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              EOT

  tags = {
    Name = "${var.project_name}-instance-b2"
    Role = "docker-host"
  }
}

resource "aws_eip" "eip_b1" {
  domain            = "vpc"
  network_interface = aws_network_interface.eni_b1.id
  depends_on        = [aws_internet_gateway.igw_b]

  tags = {
    Name = "${var.project_name}-eip-b1"
  }
}

resource "aws_eip" "eip_b2" {
  domain            = "vpc"
  network_interface = aws_network_interface.eni_b2.id
  depends_on        = [aws_internet_gateway.igw_b]

  tags = {
    Name = "${var.project_name}-eip-b2"
  }
}

# -----------------------------
# VPC Peering + cross-VPC routes
# -----------------------------
resource "aws_vpc_peering_connection" "a_to_b" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-a-to-b-peering"
  }
}

resource "aws_route" "route_a_to_b" {
  route_table_id            = aws_route_table.rt_a_public.id
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

resource "aws_route" "route_b_to_a" {
  route_table_id            = aws_route_table.rt_b_public.id
  destination_cidr_block    = var.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}
