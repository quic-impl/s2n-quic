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

resource "aws_instance" "netbench-server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  key_name = "netbench-key"
  provisioner "local-exec" {
    command = <<EOH
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -y | sh

    # curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    # chmod 0755 jq
    # Do some kind of JSON processing with ./jq
    EOH
  }

  tags = {
    Name = "netbench"
  }
}

resource "aws_key_pair" "netbench-ssh-key" {
  key_name   = "netbench-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCHFnXyleLS+CljpwFVqYbxK+jEDAQhYYSWc47P0TRv apoorv@toidiu.com"
}

data "github_repository" "s2n-quic" {
  full_name = "aws/s2n-quic"
}
