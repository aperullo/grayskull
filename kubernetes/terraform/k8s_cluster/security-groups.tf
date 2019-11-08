resource "aws_security_group" "k8s_ports" {
  name        = "k8s_ports_${terraform.workspace}"
  description = "Allow k8s cluster communication"
  vpc_id      = "${aws_vpc.k8s_vpc.id}"

  # TODO: Change to allow between specific hosts only
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = var.external_ip_list # add a CIDR block here
  }

}

resource "aws_security_group" "external_ports" {
  name        = "external_ports_${terraform.workspace}"
  description = "Allow k8s cluster communication"
  vpc_id      = "${aws_vpc.k8s_vpc.id}"

  # TODO: Change to allow between specific hosts only
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = var.external_ip_list # add a CIDR block here
  }

}