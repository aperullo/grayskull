backend "consul" {
    address = "consul:8500",
    advertise_addr = "http://consul:8300",
    path =  "vault/"
    scheme = "http"
}

listener "tcp" {
    address     = "0.0.0.0:8200"
    tls_disable = 1
    # tls_cert_file = "{{ tls_cert_file }}"
    # tls_key_file = "{{ tls_key_file }}"
}

api_addr = "http://vault:8200",
ui = true,
disable_mlock = true
