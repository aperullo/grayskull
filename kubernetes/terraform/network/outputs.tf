output "security_groups" {
	value = [aws_security_group.ports, aws_security_group.external_ports]
}

output "subnets" {
	value = [aws_subnet.subnet_1, aws_subnet.subnet_2, aws_subnet.subnet_3]
}

output "vpc" {
	value = aws_vpc.vpc
}