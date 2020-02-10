#jinja2: lstrip_blocks: "True"
nodes:
  {% for host in instances -%}
  - address: {{ host.public_ip }}
    internal_address: {{ host.private_ip }}
    hostname_override: {{ host.private_dns }}
    user: maintuser 
    role: 
    {%- if "master" in host.type %}
      - controlplane
      - etcd
    {%- endif %}
    {%- if "worker" in host.type %}
      - worker
    {%- endif %}
    ssh_key_path: ~/.ssh/grayskull-admin
  {%- if "storage" in host.type %}
    labels:
      node-role.kubernetes.io/storage: true
  {%- endif %}
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
      cgroup-driver: cgroupfs
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
