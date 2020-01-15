resource "aws_security_group" "ports" {
  name        = "${terraform.workspace}_${var.name}_ports"
  description = "Allow intra cluster communication"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.32.0.0/16"] # add a CIDR block here
  }

  tags = {
    Name = "${terraform.workspace}_${var.name}_ports"
    Environment = terraform.workspace
  }

}

resource "aws_security_group" "external_ports" {
  name        = "${terraform.workspace}_${var.name}_external_ports"
  description = "Allow communication to and from the cluster"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.external_ip_list # add a CIDR block here
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}_${var.name}_external_ports"
    Environment = terraform.workspace
  }

}