# Vault-Consul-Stack

Credit to [Jason Ross](https://github.com/rossja/docker-vault-consul) for the original repo this is based on.

A docker stack usable Vault with Consul storage backend.

## How to use this

This is a docker stack usable deployment for Vault, with storage backed by the distributed key-value store Consul.

Data is stored in a non-binded volume to allow persistence.

##### Prerequisite
Networking is conducted by Traefik load balancer because Consol can be especially picky about network addresses. Please have a Traefik container set up and alter the Traefik portion of the `docker-stack.yml` file to reflect your setup.

For this example, we set our DNS to redirect `*.test` to `127.0.0.1`. Alter the Traefik settings and your DNS settings to change the domain you access it on. The rest of these instructions assume the above.

#### Build

To build the project run: `./gradlew build`

#### Deploy

Ensure that the proxy network and metrics network exist in the swarm. If not create them: 

```
docker network create --driver=overlay --attachable proxy
```

To deploy:
```
> docker stack deploy -c <(docker-compose -f build/vault-consul.yml config) vault
Creating service vault_consul-worker
Creating service vault_vault
Creating service vault_consul

``` 

Vault and Consul will be visible now. You can see their UIs' at `https://vault.test` and `https://consul.test` respectively.

An easy way to set Vault up initially is to use the `vault-init.sh` script. Make sure you cd into the `/vault` directory where the script is located, as it can be picky about relative filepaths. The script also includes some commented-out examples of secrets you could inject as part of the set up.
```
> sh vault-init.sh
```
 
Being a distributed storage solution with redundancy, you can alter the replication number of consul-workers to suit your needs. *making sure all workers join the crowd can be tricky, verify your settings.* If quorum breaks then the Consul cluster will not be able to reform.

To do so, remove `-bootstrap-expect=1` from Consul's command in the `docker-stack.yml`, then increase the replication number and deploy.

To reset Vault and clear all data: bring down the stack, then delete the volume(s) dedicated to Consul.
```
>docker service rm vault_vault vault_consul vault_consul-worker
vault_vault
vault_consul
vault_consul-worker

> docker volume rm vault_consul_data 
vault_consul_data
```

Redeploying the stack and navigate to the vault UI will show that vault needs to be initialized. 


## Things to watch out for

Vault would like to run with:
```
cap_add:
      - "IPC_LOCK"
```
However; docker-stack does not support this by default, so instead `SKIP_SETCAP=1` is set in the `docker-stack.yml` and `"disable_mlock": true` is set in the `config.json`.

Vault is running with TLS disabled (in `config.json`), to use TLS requires certificates to be set up. Vault can act as a Certificate Authority by using the PKI secrets engine. Even without TLS Vault encrypts all data before passing it to Consul to store, so all the secrets are encrypted anyway in transit.

