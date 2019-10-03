resource "aws_instance" "swarm_master" {
  ami           = var.swarm_ami
  instance_type = var.swarm_size

  count = var.swarm_master_count

  subnet_id = "subnet-18977a41"

  tags = {
    Name        = "swarm-${var.environment}-master-${count.index}"
    Role        = "grayskull"
    Type        = "swarm"
    Environment = var.environment
  }

  key_name = var.key

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.swarm_root_size
  }

  user_data = "${file("${path.module}/user_data.sh")}"

  vpc_security_group_ids = [ "sg-1234a875", "sg-663ea201", "${aws_security_group.swarm_ports.id}" ]
}

resource "aws_instance" "swarm_worker" {
  ami           = var.swarm_ami
  instance_type = var.swarm_size

  count = var.swarm_worker_count

  subnet_id = "subnet-18977a41"

  tags = {
    Name        = "swarm-${var.environment}-worker-${count.index}"
    Role        = "grayskull"
    Type        = "swarm"
    Environment = var.environment
  }

  key_name = var.key

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.swarm_root_size
  }

  user_data = "${file("${path.module}/user_data.sh")}"

  vpc_security_group_ids = [ "sg-1234a875", "sg-663ea201", "${aws_security_group.swarm_ports.id}" ]
}
