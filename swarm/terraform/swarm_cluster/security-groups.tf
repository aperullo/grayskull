resource "aws_security_group" "swarm_ports" {
  name        = "swarm_ports"
  description = "Allow swarm cluster communication"
  vpc_id      = "${var.vpc_id}"

  # TODO: Change to allow between specific hosts only
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["172.31.0.0/16"] # add a CIDR block here
  }

}

# TODO: Make this into a list so the registry can talk to eachother.
resource "aws_security_group" "swarm_to_reg" {
  name        = "swarm_ports"
  description = "Allow swarm cluster communication"
  vpc_id      = "${var.vpc_id}"

  # TODO: Change to allow between specific hosts only
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = "${formatlist(
                      "%s/32", 
                      "${concat(
                        "${aws_instance.swarm_master[*].public_ip}",
                        "${aws_instance.swarm_worker[*].public_ip}"
                        )
                      }"
                    )}" # add a CIDR block here
  }

}
