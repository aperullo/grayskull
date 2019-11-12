resource "aws_vpc" "k8s_vpc" {
  cidr_block       = "172.32.0.0/16"

  enable_dns_hostnames = var.public_dns

  tags = {
    Name = "k8s_${terraform.workspace}_vpc"
    Environment = terraform.workspace
  }
}