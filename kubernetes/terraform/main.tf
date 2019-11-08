module "k8s_cluster" {
  source = "./k8s_cluster"
  external_ip_list = var.external_ip_list
}
