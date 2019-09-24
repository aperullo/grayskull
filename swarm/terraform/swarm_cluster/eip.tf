
resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.swarm_master[0].id}"
  allocation_id = "eipalloc-45589f78"
}