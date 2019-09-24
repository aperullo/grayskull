[all]
{% for host in instances -%}
{{ host.name }} ansible_host={{ host.private_dns }} ip={{ host.private_ip }} ansible_user=maintuser ansible_ssh_host={{ host.public_dns }} public_ip={{ host.public_ip }}
{% endfor %}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
helm_version='v2.14.3'

[swarm-master]
{% for host in instances -%}
{% if host.type == "master" -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[swarm-worker]
{% for host in instances -%}
{% if host.type == "worker" -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[swarm-setup-delegate]
{{ (instances | selectattr("type", "equalto", "master") | first())["name"] }}

[swarm-node]
{% for host in instances -%}
{% if host.type != "rancher" -%}
{{ host.name }}
{% endif -%}
{% endfor %}

[swarm-node:vars]
docker_daemon_graph=/storage/docker
swarmadm_enabled=True
helm_enabled=True
supplementary_addresses_in_ssl_keys='["{{ instances|join('", "', attribute='public_ip') }}"]'
grayskull_dir=/grayskull
platform_prefix=gsp
bin_dir=/usr/local/bin

[swarm-cluster:children]
swarm-node
swarm-master
