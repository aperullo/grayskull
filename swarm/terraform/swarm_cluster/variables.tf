variable "swarm_root_size" {
  type        = number
  default     = 40
  description = "The size in Gibibytes of the swarm root volume"
}

variable "docker_storage_size" {
  type        = number
  default     = 200
  description = "The size in Gibibytes of the docker storage volumes"
}

variable "swarm_ami" {
  type        = string
  default     = "ami-06432267"
  description = "AMI to use for the swarm nodes"
}

variable "swarm_master_count" {
  type        = number
  default     = 1
  description = "Number of swarm master nodes to provision"
}

variable "swarm_worker_count" {
  type        = number
  default     = 2
  description = "Number of swarm master nodes to provision"
}

variable "swarm_size" {
  type        = string
  default     = "t3.xlarge"
  description = "Size of instances for swarm nodes"
}

variable "environment" {
  type        = string
  default     = "staging"
  description = "Environment being deployed. Primarily used for labels"
}

variable "key" {
  type        = string
  default     = "grayskull-admin"
  description = "Key Pair to add to instances. Needed for initial access."
}

variable "vpc_id" {
  type        = string
  default     = "vpc-18c83b7c"
  description = "Vpc for deployment"
}

