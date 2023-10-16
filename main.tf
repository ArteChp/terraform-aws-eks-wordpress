provider "aws" {
  region = "us-west-1"
}

data "aws_region" "current" {}

resource "aws_vpc" "sb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sbVPC"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "wp_subnet_1" {
  vpc_id                  = aws_vpc.sb_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "wpSubnet1"
  }
}


resource "aws_subnet" "wp_subnet_2" {
  vpc_id                  = aws_vpc.sb_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 1)

  tags = {
    Name = "wpSubnet2"
  }
}

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = aws_vpc.sb_vpc.id
}


resource "aws_route_table" "wp_route_table" {
  vpc_id = aws_vpc.sb_vpc.id
}


resource "aws_route" "wp_route" {
  route_table_id         = aws_route_table.wp_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wp_internet_gateway.id
}

resource "aws_route_table_association" "private_subnet_assoc_1" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.wp_subnet_1.*.id, count.index)
  route_table_id = aws_route_table.wp_route_table.id
}

resource "aws_route_table_association" "private_subnet_assoc_2" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.wp_subnet_2.*.id, count.index)
  route_table_id = aws_route_table.wp_route_table.id
}

resource "aws_security_group" "eks_security_group" {
  name        = "EKSSecurityGroup"
  description = "EKS security group"
  vpc_id      = aws_vpc.sb_vpc.id

  ingress = [
    {
      description      = "In TCP 80"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "In TCP 443"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow all inbound traffic from within the security group"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      self             = true
      security_groups  = []
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
    },
  ]

  egress = [
    {
      description      = "Allow all outbound traffic to the Internet"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]
}


# Allocate an Elastic IP address
resource "aws_eip" "sb_dev" {
  #  network_interface         = aws_network_interface.sb_eni.id
}

