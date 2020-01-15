resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.32.0.0/20"

  map_public_ip_on_launch = var.public_dns
  # availability_zone_id = aws_route53_zone.r53_zone.zone_id

  tags = {
    Name = "${terraform.workspace}_${var.name}_subnet_1"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.32.16.0/20"

  map_public_ip_on_launch = var.public_dns
  # availability_zone_id = aws_route53_zone.r53_zone.zone_id

  tags = {
    Name = "${terraform.workspace}_${var.name}_subnet_2"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.32.32.0/20"

  map_public_ip_on_launch = var.public_dns
  # availability_zone_id = aws_route53_zone.r53_zone.zone_id

  tags = {
    Name = "${terraform.workspace}_${var.name}_subnet_3"
    Environment = terraform.workspace
  }
}