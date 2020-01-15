
module "master" {
  source = "./k8s_node"
  name = var.master_node_name
  node_count = var.master_count
  public_dns = var.public_dns
  security_groups = module.k8s_network.security_groups
  subnets = module.k8s_network.subnets
}

module "worker" {
  source = "./k8s_node"
  name = var.worker_node_name
  node_count = var.worker_count
  public_dns = var.public_dns
  security_groups = module.k8s_network.security_groups
  subnets = module.k8s_network.subnets
}

module "ceph" {
  source = "./k8s_node"
  name = var.ceph_node_name
  node_count = var.ceph_count
  public_dns = var.public_dns
  security_groups = module.k8s_network.security_groups
  subnets = module.k8s_network.subnets
}

module "ceph_storage" {
  source = "./k8s_storage"
  nodes = concat(module.worker.nodes) #, module.master.nodes)
  name = var.ceph_storage_name
  device_name = var.ceph_device_name
}

module "k8s_network" {
  source = "./network"
  name = var.network_name
  public_dns = var.public_dns
  external_ip_list = var.external_ip_list
  nodes = concat(module.master.nodes, module.worker.nodes)
}

#TODO include commented out templates for other possible node types, like masters that are also workers.