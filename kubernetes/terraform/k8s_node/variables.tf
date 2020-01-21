variable "k8s_root_size" {
  type        = number
  default     = 40
  description = "The size in Gibibytes of the k8s root volume"
}

variable "k8s_ami" {
  type        = string
  default     = "ami-54301135"
  description = "AMI to use for the k8s nodes"
}

variable "node_count" {
  type        = number
  default     = 3
  description = "Number of k8s master nodes to provision"
}

variable "k8s_size" {
  type        = string
  default     = "t3.xlarge"
  description = "Size of instances for k8s nodes"
}

variable "key" {
  type        = string
  default     = "grayskull-admin"
  description = "Key Pair to add to instances. Needed for initial access."
}

variable "public_dns" {
  type        = bool
  default     = true
  description = "Whether the nodes should be given public IPs."
}

variable "name" {
  type        = string
  description = "Name to use for organizing/tagging ec2 instances"
}

variable "security_groups" {
  type        = list
  default     = []
  description = "The security groups the nodes accept traffic from"
}

variable "subnets" {
  type        = list
  default     = []
  description = "The security groups the nodes accept traffic from"
}