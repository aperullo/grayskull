variable "external_ip_list" {
  type        = list
  description = "The ip that is allowed to talk to the nodes from external."
}

variable "public_dns" {
  type 	      = bool
  description = "Whether the nodes should be given public IPs."
}
