# formerly vpc.tf

resource "aws_vpc" "vpc" {
  cidr_block       = "172.32.0.0/16"

  enable_dns_hostnames = var.public_dns

  tags = {
    Name = "${terraform.workspace}-${var.name}-vpc"
    Environment = terraform.workspace
  }
}