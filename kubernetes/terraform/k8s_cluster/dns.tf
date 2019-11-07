# Since kube-apiserver is a docker container, it can't talk to keycloak, which runs inside the cluster. 
# This routes the requests to the clusters ingress, allowing kube-apiserver to reach it.

resource "aws_route53_record" "www" {
  zone_id = "Z27V36PIZSES82"	# TODO: either make or get this value. "${aws_route53_zone.primary.zone_id}"
  name    = "auth.${terraform.workspace}.gsp.test"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.k8s_master[0].private_ip}"] # TODO: figure out how to turn an interpolation into a list.
}
