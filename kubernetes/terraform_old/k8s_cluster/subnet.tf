resource "aws_subnet" "k8s_subnet_1" {
  vpc_id     = "${aws_vpc.k8s_vpc.id}"
  cidr_block = "172.32.0.0/20"

  map_public_ip_on_launch = var.public_dns
  # availability_zone_id = 

  tags = {
    Name = "k8s_${terraform.workspace}_subnet_1"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "k8s_subnet_2" {
  vpc_id     = "${aws_vpc.k8s_vpc.id}"
  cidr_block = "172.32.16.0/20"

  map_public_ip_on_launch = var.public_dns
  # availability_zone_id =

  tags = {
    Name = "k8s_${terraform.workspace}_subnet_2"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "k8s_subnet_3" {
  vpc_id     = "${aws_vpc.k8s_vpc.id}"
  cidr_block = "172.32.32.0/20"

  map_public_ip_on_launch = var.public_dns
  # availability_zone_id =

  tags = {
    Name = "k8s_${terraform.workspace}_subnet_3"
    Environment = terraform.workspace
  }
}