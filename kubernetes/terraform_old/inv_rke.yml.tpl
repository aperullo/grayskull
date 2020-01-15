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
  
ingress:
  provider: none

network:
  plugin: calico
  
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
      volume-plugin-dir: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
    extra_binds:
      - /usr/libexec/kubernetes/kubelet-plugins/volume/exec:/usr/libexec/kubernetes/kubelet-plugins/volume/exec
  kube-api:
    extra_args:
      oidc-client-id: "kubernetes"
      oidc-issuer-url: "https://auth.{{ env }}.gsp.test/auth/realms/master"
      oidc-username-claim: "preferred_username"
      oidc-groups-claim: "groups"
      oidc-ca-file: "/etc/kubernetes/ssl/kube-ca.pem"
