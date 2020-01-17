variable "name" {
  type        = string
  description = "Name to prefix in EC2 dashboard"
} 

variable "subnets" {
  type        = list
  description = "subnet to attach to load balancer"
}

variable "vpc" {
#  type        = string
  description = "vpc to attach to load balancer"
}

variable "nodes" {
  type        = list
  description = "nodes to attach to load balancer"
}
