# ELK Stack

## Building

To build the project run: `./gradlew build`

## Working with remote swarms

If working with a remote swarm, make sure the `DOCKER_HOST` and `DOCKER_TLS_VERIFY` environment variables are set prior to using the docker cli

## Initial Setup

Ensure that the proxy network exists in the swarm. If not create them: 

```
docker network create --driver=overlay --attachable proxy
```
## Deploying

*Note:* Make sure to create a `build/.env` file containing any overrides for variables used in the stack deployment

```
cd build
docker stack deploy -c <(docker-compose -f elk.yml config) elk
```


