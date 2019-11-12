resource "aws_security_group" "k8s_ports" {
  name        = "k8s_ports_${terraform.workspace}"
  description = "Allow k8s cluster communication"
  vpc_id      = "${aws_vpc.k8s_vpc.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.32.0.0/16"] # add a CIDR block here
  }

  tags = {
    Name = "k8s_ports_${terraform.workspace}"
    Environment = terraform.workspace
  }

}

resource "aws_security_group" "external_ports" {
  name        = "external_ports_${terraform.workspace}"
  description = "Allow communication to and from k8s cluster"
  vpc_id      = "${aws_vpc.k8s_vpc.id}"

  ingress {
    # TLS (change to whatever ports you need)
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
    Name = "k8s_external_ports_${terraform.workspace}"
    Environment = terraform.workspace
  }

}