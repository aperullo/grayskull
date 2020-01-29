locals {
  user_data_file_path = "${path.module}/user_data.sh"
}

resource "aws_instance" "k8s_node" {
  ami           = var.k8s_ami
  instance_type = var.k8s_size

  count = var.node_count

  subnet_id = var.subnets[0].id

  tags = {
    Name        = "${terraform.workspace}-${var.name}-${count.index}"
    Role        = "grayskull"
    Type        = "k8s"
    Environment = terraform.workspace
  }

  key_name = var.key

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.k8s_root_size
  }

  vpc_security_group_ids = var.security_groups[*].id

  #vpc_security_group_ids = [ "${aws_security_group.k8s_ports.id}", "${aws_security_group.external_ports.id}" ]
}
