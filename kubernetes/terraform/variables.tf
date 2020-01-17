
#---- Master vars

variable "master_node_name" {
  type        = string
  default     = "k8s-master"
  description = "Name for the master nodes in EC2 dashboard"
} 

variable "master_count" {
  type        = number
  default     = 3
  description = "count of masters"
} 

#---- Worker vars

variable "worker_node_name" {
  type        = string
  default     = "k8s-worker"
  description = "Name for the worker nodes in EC2 dashboard"
} 

variable "worker_count" {
  type        = number
  default     = 3
  description = "Count of workers"
} 

#---- Ceph node vars

variable "ceph_node_name" {
  type        = string
  default     = "k8s-ceph"
  description = "Name for the ceph nodes in EC2 dashboard"
} 

variable "ceph_count" {
  type        = number
  default     = 0  # 3  
  description = "Count of storage nodes"
} 

#---- Ceph volume vars

variable "ceph_storage_name" {
  type        = string
  default     = "k8s-ceph-vol"
  description = "Name for the ceph volumes in EC2 dashboard"
} 

variable "ceph_device_name" {
  type        = string
  default     = "/dev/sdf"
  description = "Name for the ceph volumes in EC2 dashboard"
}

#---- Networking vars

variable "network_name" {
  type        = string
  default     = "k8s-network"
  description = "Name to add to all the network related resources"
} 

variable "external_ip_list" {
  type        = list
  description = "The ip that is allowed to talk to the nodes from external."
}

variable "public_dns" {
  type        = bool
  description = "Whether the nodes should be given public IPs."
}

#---- Loadbalancer

variable "lb_name" {
  type        = string
  default     = "k8s-lb"
  description = "Name to add to all the lb resources"
}