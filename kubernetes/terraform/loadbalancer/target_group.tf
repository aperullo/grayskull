resource "aws_lb_target_group" "k8s_target_group" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc.id

  tags = {
    Name = "${terraform.workspace}_${var.name}_listener"
    Environment = terraform.workspace
  }
}

resource "aws_lb_target_group_attachment" "k8s_target_group_assoc_80" {
  count            = length(var.nodes)

  target_group_arn = aws_lb_target_group.k8s_target_group.arn
  target_id        = var.nodes[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "k8s_target_group_assoc_443" {
  count            = length(var.nodes)

  target_group_arn = aws_lb_target_group.k8s_target_group.arn
  target_id        = var.nodes[count.index].id
  port             = 443
}