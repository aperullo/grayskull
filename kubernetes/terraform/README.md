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

### Ansible Inventory

To generate an ansible inventory file based on the current terraform state go to the `kubernetes/terraform` directory and run `./scripts/generate_inventory > ../ansible/inventory/<name_of_inventory>.ini`

### SSH Config

To generate an ssh config based on current terraform state go to the `kubernetes/terraform` directory and run `./scripts/generate_ssh_config > /tmp/ssh_config` and use with `ssh -F /tmp/ssh_config ...`
