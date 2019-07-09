resource "aws_security_group" "k8s_ports" {
  name        = "k8s_ports"
  description = "Allow k8s cluster communication"
  vpc_id      = "${var.vpc_id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["172.31.0.0/16"] # add a CIDR block here
  }

}
