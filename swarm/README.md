# Grayskull K8S deployment guide

This document represents instructions on how to deploy grayskull and its services on docker swarm.

## Prerequisites

### Swarm prerequisites
- A number of vms to act as nodes, running Centos

### Local machine prerequisites

- Ansible version >= `2.8.5`
- Hashicorp terraform
- (Optional) AWS command line tool through an account for provisioning nodes.

## Process

### Provision the virtual machines

If your aws command line tool is set up, you can navigate to `swarm/terraform.`

1. `terraform plan`. Verify the plan looks as you expect
2. `terraform apply`. Provision the VMs.
3. `scripts/generate_inventory > ../ansible/inventory/myinv.ini`. Create an ansible inventory to be used later
4. `scripts/generate_ssh_config > /tmp/ssh_config`. Create a temporary set of ssh credentials for you and ansible to use on the VMs.
5. `eval $(ssh-agent)`
6. `ssh-add ~/.ssh/grayskull-admin`

### Deploy with Ansible

There is a playbook which will run through the whole process for setting up the swarm.
Find it in `swarm/ansible/swarm.yml`. Run it using the inventory as targets. From the ansible folder:

```
> ansible-playbook -i inventory/myinv.ini swarm.yml
PLAY RECAP ***********************************************************************************************************
swarm-staging-master-0     : ok=54   changed=41   unreachable=0    failed=0    skipped=4    rescued=0    ignored=0   
swarm-staging-worker-0     : ok=36   changed=31   unreachable=0    failed=0    skipped=9    rescued=0    ignored=0   
swarm-staging-worker-1     : ok=36   changed=31   unreachable=0    failed=0    skipped=9    rescued=0    ignored=0  

```

### Get the credentials

Ansible generates certs for the docker daemon to protect it. To retrive them, ssh into the primary master node (swarm-setup-delegate in the inventory), you will find them under /grayskull.
Copy `ca.pem`, `cert.pem`, `cert-key.pem` to your local machine, then setup/use the `gc-docker.sh` script to issue commands to the remote daemon.