resource "aws_lb" "k8s_lb" {
  name               = "${terraform.workspace}-${var.name}-lb"
  internal           = false
  load_balancer_type = "network"
  
  subnet_mapping {
    subnet_id        = var.subnets[0].id
    allocation_id    = aws_eip.k8s_eip.id
  }

  enable_deletion_protection = false

  tags = {
    Name = "${terraform.workspace}_${var.name}_loadbalancer"
    Environment = terraform.workspace
  }
}

resource "aws_lb_listener" "k8s_lb_listener_80" {
  load_balancer_arn  = aws_lb.k8s_lb.arn
  port               = "80"
  protocol           = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_target_group.arn
  }

}

resource "aws_lb_listener" "k8s_lb_listener_443" {
  load_balancer_arn  = aws_lb.k8s_lb.arn
  port               = "443"
  protocol           = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_target_group.arn
  }

}