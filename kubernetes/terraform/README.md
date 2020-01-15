# K8S on AWS

This is a small terraform module to bootstrap a set of hosts meant for deploying a k8s cluster.
The module simply sets up the infrastructure and does not actually install anything since that will be done later by ansible.

# Requirements

* Install Terraform
* Install aws cli
* Configure authentication for [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration)

# Usage

1. Run `terraform init` to load the current state of the aws resources
2. Run `terraform plan` and review output to examine any necessary changes to infrastructure
3. Assuming planned changes are good, run `terraform apply` to execute changes to infrastructure

## Helper Scripts

There are a few helper scripts included to assist with tasks

### SSH Config

To generate an ssh config based on current terraform state go to the `kubernetes/terraform` directory and run `./scripts/generate_ssh_config > /tmp/ssh_config` and use with `ssh -F /tmp/ssh_config ...`

### Ansible Inventory

To generate an ansible inventory file based on the current terraform state go to the `kubernetes/terraform` directory and run the following:

1. `scripts/generate_inventory -t scripts/templates/inv_rke.yml.tpl> ../ansible/inventory/rke.yml`
2. `scripts/generate_inventory -t scripts/templates/inv_ansible.ini.tpl > ../ansible/inventory/rke.ini`


## Editing the infrastructure

The infrastructure is assembled in the `main.tf` and `variables.tf` out of several modules called repeatedly.

- **k8s_node**: Represents a number of ec2 instances
- **k8s_storage**: Creates volumes and attachments for any nodes passed into it
- **network**: Represents the vpc, security groups, dns, and other aspects that allow intra-cluster and external communication.

### k8s_node

The `main.tf` is meant to be edited to suit the infrastructure needs. Our scripts only look for 3 types of nodes (`master`, `worker`, `storage`), but additional can be defined by simply renaming the relevant aspects. See this block for example:

```
module "master" {
  source = "./k8s_node"
  name = var.master_node_name
  node_count = var.master_count
  security_groups = module.k8s_network.security_groups
  subnets = module.k8s_network.subnets
}
```

We could add another and simply change the module name from `master` to `etcd`, create the corresponding variables in `variables.tf` and we now have a new type of node that we can dedicate to etcd.

### k8s_storage

This module takes in a list of nodes from other modules and will create and attach volume storage to them.

```
module "ceph_storage" {
  source = "./k8s_storage"
  nodes = concat(module.master.nodes, module.worker.nodes)   # module.master.nodes
  name = var.ceph_storage_name
}
```

In this example we are attaching storage to all the nodes created in our previously shown k8s_node module invocations as masters, and another of workers.

### network

The network module is responsible for enabling communication to, from, and between nodes. 

```
module "k8s_network" {
  source = "./network"
  name = var.network_name
  public_dns = var.public_dns
  external_ip_list = var.external_ip_list
  nodes = concat(module.master.nodes, module.worker.nodes)
}
```

It accepts whether we want the domains to be publically addressable through `public_dns`, as well as the external IP addresses that are allowed to contact nodes threough `external_ip_list`. Finally it takes the nodes that need to talk to eachother and that will possibly be connected to from outside as `nodes`.
