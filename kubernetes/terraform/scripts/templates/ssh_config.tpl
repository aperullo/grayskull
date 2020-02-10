{% for host in instances %}
Host {{ host.name }}
  Hostname {{ host.public_dns }}
  user maintuser
  IdentityFile ~/.ssh/grayskull_admin
{% endfor %}
