nodes:
  {% for host in instances -%}
  {% if host.type == "master" -%}
  - address: {{ host.public_ip }}
    internal_address: {{ host.private_ip }}
    user: maintuser
    role: [controlplane,etcd]
    ssh_key_path: ~/.ssh/grayskull-admin
  {% endif -%}
  {% if host.type == "worker" -%}
  - address: {{ host.public_ip }}
    internal_address: {{ host.private_ip }}
    user: maintuser
    role: [worker]
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