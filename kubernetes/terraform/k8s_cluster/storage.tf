resource "aws_ebs_volume" "ceph_storage_master" {
  count = var.k8s_master_count

  size = var.ceph_storage_size

  tags = {
    Name        = "k8s-${var.environment}-master-${count.index}"
    Role        = "grayskull"
    Type        = "ceph storage"
    Environment = var.environment
  }

  availability_zone = aws_instance.k8s_master[count.index].availability_zone
}

resource "aws_ebs_volume" "ceph_storage_worker" {
  count = var.k8s_worker_count

  size = var.ceph_storage_size

  tags = {
    Name        = "k8s-${var.environment}-worker-${count.index}"
    Role        = "grayskull"
    Type        = "ceph storage"
    Environment = var.environment
  }

  availability_zone = aws_instance.k8s_worker[count.index].availability_zone
}

resource "aws_volume_attachment" "ceph_storage_master_ec2" {
  count = var.k8s_master_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ceph_storage_master[count.index].id
  instance_id = aws_instance.k8s_master[count.index].id
}

resource "aws_volume_attachment" "ceph_storage_worker_ec2" {
  count = var.k8s_worker_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ceph_storage_worker[count.index].id
  instance_id = aws_instance.k8s_worker[count.index].id
}
