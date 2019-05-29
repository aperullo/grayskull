# Vault-File-Stack

A basic vault stack, backed by file storage. 

## Building

To build the project run: `./gradlew build`

## Initial Setup

Ensure that the proxy network exists in the swarm. If not create them: 

```
> docker network create --driver=overlay --attachable proxy
```
## Deploying
To deploy use:

```
> docker stack deploy -c <(docker-compose -f build/vault.yml config) vault
Creating service vault_vault
```
