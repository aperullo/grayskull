resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = "${aws_vpc.k8s_vpc.id}"

  tags = {
    Name = "k8s_${terraform.workspace}_igw"
    Environment = terraform.workspace
  }
}

resource "aws_default_route_table" "r" {
  default_route_table_id = "${aws_vpc.k8s_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.k8s_igw.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = "${aws_internet_gateway.k8s_igw.id}"
  }

  tags = {
    Name = "k8s_${terraform.workspace}_rt"
    Environment = terraform.workspace
  }
}