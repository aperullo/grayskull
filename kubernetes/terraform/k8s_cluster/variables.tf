variable "k8s_root_size" {
  type        = number
  default     = 40
  description = "The size in Gibibytes of the k8s root volume"
}

variable "ceph_storage_size" {
  type        = number
  default     = 200
  description = "The size in Gibibytes of the ceph storage volumes"
}

variable "k8s_ami" {
  type        = string
  default     = "ami-06432267"
  description = "AMI to use for the k8s nodes"
}

variable "k8s_master_count" {
  type        = number
  default     = 3
  description = "Number of k8s master nodes to provision"
}

variable "k8s_worker_count" {
  type        = number
  default     = 3
  description = "Number of k8s master nodes to provision"
}

variable "k8s_size" {
  type        = string
  default     = "t3.xlarge"
  description = "Size of instances for k8s nodes"
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

