# Create Test Self-signed certs

## Generating Certificates
1. Install cfssl and cfssljson
2. Download the correct platform specific binaries from https://pkg.cfssl.org/
3. Place them somewhere in the $PATH
4. Create a csr.json file. Replace values in file as needed
5. Create a self-signed ca: `cfssl genkey -initca csr.json | cfssljson -bare ca`
6. Create a certificate for the proxy: `cfssl gencert -ca ca.pem -ca-key ca-key.pem csr.json | cfssljson -bare cert`
7. Create a certificate chain: `cat cert.pem ca.pem >> chain.pem`
8. Copy cert-key.pem and chain.pem to where they are needed.
