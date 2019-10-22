# Rancher deployment guide

A rancher HA cluster is a dedicated kubernetes cluster whose only tasks are to run rancher and related work loads. Actual product clusters are provisioned and administrated from the ui/api of this dedicated rancher cluster.

Getting a rancher HA cluster running can be challenging. The steps are:
1. Create/provision nodes
2. Install kubernetes with RKE (a kubernetes installer)
3. Initialize helm and install rancher through it.

## Prerequisites

### Cluster prerequisites

- A number of vms to act as nodes.
- Centos 7.6 for all K8s nodes.
- A [compatible](https://rancher.com/docs/rancher/v2.x/en/installation/requirements/) Docker version. Can be part of the base image or installed post provisioning.
- Firewall on the nodes will need to be off, or set up to allow only the correct ports
`sudo systemctl stop firewalld`
- (Optional) Python 2 for Ansible

Run the git command to load the submodule:
`git submodule update --init --recursive`

### Local machine prerequisites

- Ansible version `2.7.10`
- Hashicorp terraform
- Rancher RKE for setting up kubernetes clusters
- (Optional) AWS command line tool through an account for provisioning nodes


## Provision the virtual machines

TODO: *Cgroup errors*: cgroups disabled, see ticket for more.

If your aws command line tool is set up, you can navigate to `kubernetes/terraform.`

1. `terraform plan`. Verify the plan looks as you expect
2. `terraform apply`. Provision the VMs.
3. `scripts/generate_ssh_config > /tmp/ssh_config`. Create a temporary set of ssh credentials for you. 
4. `eval $(ssh-agent)`
5. `ssh-add ~/.ssh/grayskull-admin`

**IMPORTANT:** The nodes will provision but will take several extra minutes before we can run RKE over them. SSH into one of the nodes and check if `4.txt` is in `/` with `ls /`. If it isn't, the userdata script is still running and the node is not ready yet.

## The userdata script

*This section just represents information, no action is taken in this section*

The script has 4 main parts. It is not reproduced here as it is subject to change.

1. We give each node an extra 200gb of space, this section sets up the logical volumes so they can be used.

2. In the next step we install docker, start it up, and add our user to the docker group.
TODO: Don't have to add user to docker group.

3. `/var` only has about 2gb of space, and that quickly fills as docker downloads images. So we stop docker, relocate `/var/lib/docker` to `/storage/docker` and create a symlink so that any operations to `/var/lib/docker` actually happen in `/storage/docker`

4. We stop the firewalls so the hosts can communicate with eachother, then we restart docker to clear its iptable rules.

## Deploy Kubernetes with RKE

:warning: Choose the section below that corresponds to your goal:
- To deploy Grayskull with RKE see **[Grayskull with RKE](RKE_Grayskull.md)**
- To deploy Rancher with RKE see **[Rancher with RKE](RKE_Rancher.md)**


