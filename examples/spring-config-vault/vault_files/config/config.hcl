disable_cache = true
disable_mlock = true
max_lease_ttl = "10h"
default_lease_ttl = "10h"

ui = true

storage "file" {
    path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
