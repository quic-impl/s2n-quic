/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */
/* SPDX-License-Identifier: Apache-2.0 */


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.13"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_key_pair" "netbench-ssh-key" {
  key_name   = "netbench-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCHFnXyleLS+CljpwFVqYbxK+jEDAQhYYSWc47P0TRv apoorv@toidiu.com"

  tags = {
    Name = "netbench"
  }
}

data "github_repository" "s2n-quic" {
  full_name = "aws/s2n-quic"
}

resource "aws_vpc" "netbench" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "netbench"
  }
}

resource "aws_route_table" "netbench" {
  vpc_id = aws_vpc.netbench.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.netbench.id
  }

  tags = {
    Name = "netbench"
  }
}

resource "aws_main_route_table_association" "netbench" {
  vpc_id         = aws_vpc.netbench.id
  route_table_id = aws_route_table.netbench.id
}

resource "aws_internet_gateway" "netbench" {
  vpc_id = aws_vpc.netbench.id

  tags = {
    Name = "netbench"
  }
}

resource "aws_subnet" "netbench" {
  vpc_id     = aws_vpc.netbench.id
  availability_zone_id = "usw2-az1"
  cidr_block = "172.31.16.0/20"
  map_public_ip_on_launch = true

  tags = {
    Name = "netbench"
  }
}

resource "aws_security_group" "netbench" {
  name        = "netbench"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.netbench.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "netbench"
  }
}

resource "aws_network_interface" "netbench" {
  subnet_id   = aws_subnet.netbench.id
  security_groups = [aws_security_group.netbench.id]

  tags = {
    Name = "netbench"
  }
}

resource "aws_instance" "netbench-server" {
  /* ami           = "ami-830c94e3" */
  ami           = "ami-0ca285d4c2cda3300"
  instance_type = "t2.micro"
  key_name = "netbench-key"

  network_interface {
    network_interface_id = aws_network_interface.netbench.id
    device_index         = 0
  }


  /* provisioner "local-exec" { */
  /*   command = <<EOH */
  /*   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -y | sh */

  /*   # curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 */
  /*   # chmod 0755 jq */
  /*   # Do some kind of JSON processing with ./jq */
  /*   EOH */
  /* } */

  tags = {
    Name = "netbench"
  }
}
