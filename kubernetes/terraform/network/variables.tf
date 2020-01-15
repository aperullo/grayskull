variable "nodes" {
  type        = list
  description = "The nodes to use for the dns records"
}

variable "name" {
  type		  = string
  description = "The name to prepend to the resource/tags in amazon EBS"
}

variable "external_ip_list" {
  type        = list
  description = "The ip that is allowed to talk to the nodes from external."
}

variable "public_dns" {
  type 	      = bool
  description = "Whether the nodes should be given public IPs."
}