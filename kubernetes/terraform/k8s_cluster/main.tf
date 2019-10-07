resource "aws_instance" "k8s_master" {
  ami           = var.k8s_ami
  instance_type = var.k8s_size

  count = var.k8s_master_count

  subnet_id = "subnet-18977a41"

  tags = {
    Name        = "k8s-${var.environment}-master-${count.index}"
    Role        = "grayskull"
    Type        = "k8s"
    Environment = var.environment
  }

  key_name = var.key

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.k8s_root_size
  }

  user_data = "${file("${path.module}/user_data.sh")}"

  vpc_security_group_ids = [ "sg-1234a875", "sg-663ea201", "${aws_security_group.k8s_ports.id}" ]
}

resource "aws_instance" "k8s_worker" {
  ami           = var.k8s_ami
  instance_type = var.k8s_size

  count = var.k8s_worker_count

  subnet_id = "subnet-18977a41"

  tags = {
    Name        = "k8s-${var.environment}-worker-${count.index}"
    Role        = "grayskull"
    Type        = "k8s"
    Environment = var.environment
  }

  key_name = var.key

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.k8s_root_size
  }

  user_data = "${file("${path.module}/user_data.sh")}"

  vpc_security_group_ids = [ "sg-1234a875", "sg-663ea201", "${aws_security_group.k8s_ports.id}" ]
}

resource "aws_instance" "k8s_rancher" {
  ami           = var.k8s_rancher_ami
  instance_type = var.k8s_size

  count = var.k8s_rancher_count

  subnet_id = "subnet-18977a41"

  tags = {
    Name        = "k8s-${var.environment}-rancher-${count.index}"
    Role        = "grayskull"
    Type        = "k8s"
    Environment = var.environment
  }

  root_block_device {
    volume_size = var.k8s_root_size
  }

  key_name = var.key

  associate_public_ip_address = true

  user_data = "${file("${path.module}/rancher_data.sh")}"

  vpc_security_group_ids = [ "sg-1234a875", "sg-663ea201", "sg-fb90fd9c", "${aws_security_group.k8s_ports.id}" ]
}