variable "nodes" {
  type        = list
  description = "The node ids to make and attach storage to"
}

variable "storage_size" {
  type        = number
  default     = 200
  description = "The size in Gibibytes of the ceph storage volumes"
}

variable "name" {
  type		  = string
  description = "The name to prepend to the resource/tags in amazon EBS"
}

variable "device_name" {
  type		  = string
  description = "The name to prepend to the resource/tags in amazon EBS"
}