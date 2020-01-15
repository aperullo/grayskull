locals {
  storage_count = length(var.nodes)
}

resource "aws_ebs_volume" "storage" {
  count = local.storage_count

  size = var.storage_size

  tags = {
    Name        = "${terraform.workspace}-${var.name}-storage-${count.index}"
    Role        = "grayskull"
    Type        = "volume"
    Environment = terraform.workspace
  }

  availability_zone = var.nodes[count.index].availability_zone
}

resource "aws_volume_attachment" "storage_attach" {
  count = local.storage_count

  device_name = var.device_name
  volume_id   = aws_ebs_volume.storage[count.index].id
  instance_id = var.nodes[count.index].id
}
