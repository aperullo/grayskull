# Since kube-apiserver is a docker container, it can't talk to keycloak, which runs inside the cluster. 
# This routes the requests to the clusters ingress, allowing kube-apiserver to reach it.

resource "aws_route53_zone" "r53_zone" {
  name = "${terraform.workspace}.gsp.test"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }

  tags = {
    Name = "${terraform.workspace}_${var.name}_zone"
    Environment = terraform.workspace
  }
}

resource "aws_route53_record" "wildcard_record" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "*.${terraform.workspace}.gsp.test"
  type    = "A"
  ttl     = "300"
  records = var.nodes[*].private_ip
}
