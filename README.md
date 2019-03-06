# Project Grayskull

Deploy a local or remote docker swarm based development platform

See [Local Development Setup](docs/local-development-setup.md)

## Building

Simply run `./gradlew build`

## Running

### docker-compose

To deploy via docker-compose run `docker-compose -f deployments/build/docker-compose.yml up -d`

### docker swarm

To deploy as a swarm stack run `docker stack deploy -c deployments/build/docker-compose.yml platform`

