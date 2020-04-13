[all]
{% for host in instances -%}
{{ host.name }} ansible_host={{ host.private_dns }} ip={{ host.private_ip }} ansible_user=maintuser ansible_ssh_host={{ host.public_dns }} public_ip={{ host.public_ip }}
{% endfor -%}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
helm_version='v3.1.1'
kubectl_version='v1.17.2'
gitops_repo_dir=/grayskull/gitops-repo

[kube-master]
{% for host in instances -%}
{% if "master" in host.type -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[kube-setup-delegate]
{% set inst = [] -%}
{% for host in instances -%}
{% if "master" in host.type -%}
{% do inst.append(host.name) -%}
{% endif -%}
{% endfor -%}
{{ inst | first }}

[kube-node]
{% for host in instances -%}
{{ host.name }}
{% endfor %}

[kube-worker]
{% for host in instances -%}
{% if "worker" in host.type -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[kube-storage]
{% for host in instances -%}
{% if "storage" in host.type -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[kube-node:vars]
docker_daemon_graph=/storage/docker
kubeadm_enabled=True
helm_enabled=True
supplementary_addresses_in_ssl_keys='["{{ instances|join('", "', attribute='public_ip') }}"]'
grayskull_dir=/grayskull
platform_prefix=gsp
bin_dir=/usr/local/bin
grayskull_domain={{ env }}.gsp.test
kubeconfig_src=../inventory/kube_config_{{ env }}.yml

[etcd]
{% for host in instances -%}
{% if "master" in host.type -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[k8s-cluster:children]
kube-node
kube-master

[calico-rr]

[vault]
{% for host in instances -%}
{% if "master" in host.type -%}
{{ host.name }}
{% endif -%}
{% endfor -%}

