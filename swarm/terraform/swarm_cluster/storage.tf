resource "aws_ebs_volume" "docker_storage_master" {
  count = var.swarm_master_count

  size = var.docker_storage_size

  tags = {
    Name        = "swarm-${terraform.workspace}-master-${count.index}"
    Role        = "grayskull"
    Type        = "docker storage"
    Environment = terraform.workspace
  }

  availability_zone = aws_instance.swarm_master[count.index].availability_zone
}

resource "aws_ebs_volume" "docker_storage_worker" {
  count = var.swarm_worker_count

  size = var.docker_storage_size

  tags = {
    Name        = "swarm-${terraform.workspace}-worker-${count.index}"
    Role        = "grayskull"
    Type        = "docker storage"
    Environment = terraform.workspace
  }

  availability_zone = aws_instance.swarm_worker[count.index].availability_zone
}

resource "aws_volume_attachment" "docker_storage_master_ec2" {
  count = var.swarm_master_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.docker_storage_master[count.index].id
  instance_id = aws_instance.swarm_master[count.index].id
}

resource "aws_volume_attachment" "docker_storage_worker_ec2" {
  count = var.swarm_worker_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.docker_storage_worker[count.index].id
  instance_id = aws_instance.swarm_worker[count.index].id
}
