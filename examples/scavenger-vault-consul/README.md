# Vault-Consul-Stack

This app contains an encoded message, and there is a file containing the decoding key. It doesn't know where this file is, so it needs a secret from vault to know where "answer.txt" is located. Vault has this secret, and requires the app to have a token to retrieve it.

This version use Vault with a Consul backend, set up by a `vault-init.sh`. It is a proof of concept of using Vault with Consul.

## How to use this

Data is stored in a non-binded volume to allow persistence.

##### Prerequisite
Networking is conducted by Traefik load balancer because Consul can be especially picky about network addresses. Please have a Traefik container set up and alter the Traefik portion of the `docker-stack.yml` file to reflect your setup.

For this example, we set our DNS to redirect `*.test` to `127.0.0.1`. Alter the Traefik settings and your DNS settings to change the domain you access it on. The rest of these instructions assume the above.

#### Steps

Build the docker image from the `/src` directory, name it scavenger.
```
> docker build -t scavenger .
```

To deploy:
```
> docker stack deploy -c ../docker-stack.yml vault
Creating service vault_scavenger
Creating service vault_consul-worker
Creating service vault_vault
Creating service vault_consul
``` 
Set up Vault, an easy way to set Vault up initially is to use the `vault-init.sh` script. Make sure you cd into the `/vault` directory where the script is located, as it can be picky about relative filepaths. 

The script will initialize Vault, unseal it, create a secret, then create a read-only policy for our app to use. 
**MAKE NOTE OF THE TOKEN**, otherwise the scavenger won't be able to authenticate.
```
> pwd
...Vault-Consul-Stack/vault
> sh vault-init.sh
...
Key                  Value
---                  -----
token                s.KnRiwsmfACemQ3AqG0pu9GZB
token_accessor       Co1DwQVx11EPiTHIL986B1kt
token_duration       767h59m59s
token_renewable      true
token_policies       ["app" "default"]
identity_policies    []
policies             ["app" "default"]
```

To fetch the secret and decode the message do the following using the token:
```
> curl "http://scav.test/get-secret?token=s.KnRiwsmfACemQ3AqG0pu9GZB"
TOPSECRET
```

To reset Vault and clear all data: bring down the stack, then delete the volume(s) dedicated to Consul.
```
> docker service rm vault_vault vault_consul vault_consul-worker vault_scavenger
vault_vault
vault_consul
vault_consul-worker

> docker volume rm vault_consul_data 
vault_consul_data
```
When you bring the stack back up you will have to run `vault-init.sh` again.


