disable_cache = true
disable_mlock = true
max_lease_ttl = "10h"
default_lease_ttl = "10h"
api_addr = "http://vault:8200"

# visit /ui to get a ui
ui = true

# Set data storage mode to encrypted files, then set the path of where to keep that data.
storage "file" {
    path = "/home/vault/data"
}

# listens for commands on vault's http api, disabling secure connections since we don't have certificates we are sharing
listener "tcp" {
    address     = "0.0.0.0:8200"
    tls_disable = 1
    # tls_cert_file = "{{ tls_cert_file }}"
    # tls_key_file = "{{ tls_key_file }}"
}



