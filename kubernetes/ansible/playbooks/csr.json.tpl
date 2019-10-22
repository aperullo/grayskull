{
    "CN": "House Atreides",
    "hosts": [
        {% for host in groups['all'] -%}
        "{{ hostvars[host]['ansible_host'] }}",
        {% endfor -%}
        "*.gsp.test",
        "ingress.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C":  "Atreides Empire",
            "L":  "Arrakeen",
            "O":  "Fremen",
            "OU": "Arrakis",
            "ST": "Canopus"
        }
    ]
}