output "nodes" {
	value = aws_instance.k8s_node[*]
}