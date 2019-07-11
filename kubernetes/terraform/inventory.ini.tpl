[all]
{% for host in instances -%}
{{ host.name }} ansible_host={{ host.private_dns }} ip={{ host.private_ip }} ansible_user=maintuser ansible_ssh_host={{ host.public_dns }} public_ip={{ host.public_ip }}
{% endfor %}

[kube-master]
{% for host in instances -%}
{% if host.type == "master" -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[kube-setup-delegate]
{{ (instances | selectattr("type", "equalto", "master") | first())["name"] }}

[kube-node]
{% for host in instances -%}
{{ host.name }}
{% endfor %}

[kube-node:vars]
docker_daemon_graph=/storage/docker
kubeadm_enabled=True
helm_enabled=True
supplementary_addresses_in_ssl_keys='["{{ instances|join('", "', attribute='public_ip') }}"]'
grayskull_dir=/grayskull
grayskull_name=gsp
helm_enabled=True
bin_dir=/usr/local/bin

[etcd]
{% for host in instances -%}
{% if host.type == "master" -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[k8s-cluster:children]
kube-node
kube-master

[calico-rr]

[vault]
{% for host in instances -%}
{% if host.type == "master" -%}
{{ host.name }}
{% endif -%}
{% endfor %}

