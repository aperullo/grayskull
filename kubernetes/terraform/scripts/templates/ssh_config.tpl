{% for host in instances %}
Host {{ host.name }}
  Hostname {{ host.public_dns }}
  user ubuntu
  IdentityFile ~/.ssh/grayskull_admin
{% endfor %}
