nodes:
  {% for host in instances -%}
  {% if host.type != "rancher" -%}
  - address: {{ host.public_ip }}
    internal_address: {{ host.private_ip }}
    user: maintuser
    role: [controlplane,worker,etcd]
    ssh_key_path: ~/.ssh/grayskull-admin
  {% endif -%}
  {% endfor %}

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
  kubelet:
    MountFlags: shared
    extra_args:
      cgroup-root: "/cgroup:/sys/fs/cgroup"
      cgroup-driver: cgroupfs
      cgroups-per-qos: false