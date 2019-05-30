# Project Grayskull

Project Grayskull provides resources, guidelines, and examples to enable the migration of the platform to a *microservice* architecture utilizing *containers* such as Docker with an orchestration engine (i.e. Kubernetes). This will improve the ability for teams to make critical rapid and isolated changes improving the overall productivity and responsiveness of our development teams.
Available Resource to date:
1. Container Orchestration Infrastructure options:
    - Docker Swarm
    - Kubernetes (future) 
2. Microservice resources to enable integration:
    - **Keycloak**: Centralized authentication provider
    - **Elk/Metrics**: Augmentable health/performance metrics for the platform and for applications
    - **S3 Storage**: Storage allocation and interaction service using a standarized API 
3. Available Guidelines and Coding Examples
    - Dockerizing an application
    - Spring integrating with Elk
    - Spring integrating with Minio (S3/Object storage)

See [Local Development Setup](docs/local-development-setup.md)

## Building

Simply run `./gradlew build`

## Running

### docker-compose

To deploy via docker-compose run `docker-compose -f deployments/build/docker-compose.yml up -d`

### docker swarm

To deploy as a swarm stack run `docker stack deploy -c deployments/build/docker-compose.yml platform`
