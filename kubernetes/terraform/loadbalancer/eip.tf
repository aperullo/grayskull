resource "aws_eip" "k8s_eip" {
  vpc              = true

  tags = {
    Name = "${terraform.workspace}_${var.name}_listener"
    Environment = terraform.workspace
  }
}