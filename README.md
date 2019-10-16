# Project Grayskull


Project Grayskull provides a platform with resources, guidelines, and examples to enable a *microservice* architecture utilizing *containers* such as Docker with an orchestration engine like Kubernetes. This will improve the ability for teams to make critical rapid and isolated changes improving the overall productivity and responsiveness of our development teams.

Microservice resources to enable integration:
  - **OIDC/OAUTH**: Centralized authentication provider can control access to both the orchestration cluster and applications running in said cluster.
  - **Logging and Metrics**: Augmentable health/performance metrics for the platform and for applications, via transparently exposed services.
  - **Distributed Storage**: Storage allocation and interaction service using a standarized API. 
  - **Auto-scaling**: Applications can automatically scale based on load.
  - **Administration**: User-friendly resources for managing applications inside the cluster.

## Running

Each implementation of Project Grayskull has deploy instructions, for specific instructions see the corresponding guide below.

### Kubernetes

To deploy grayskull in a kubernetes cluster, follow the instructions in the [Kubernetes deployment guide](docs/kubernetes/K8s_deploy_guide.md).

### Grayskull platform services on Kubernetes

Once project grayskull is deployed, you can utilize the available services by checking the following the links below.

To talk with kubernetes you will use kubectl, please see the Keycloak section below to set up kubectl for accessing the cluster.

Adding `-n <namespace>` to most kubectl commands will make them only work within that namespace (this only applies if your role allows you to edit things outside your namespace, otherwise you are limited to only your namespace). 
```
# view all pods within your namespace
> kubectl -n <namespace> get pods
...
```

Available services are:
1. [**Keycloak**](docs/kubernetes/features/authentication.md) for authentication and user management.
2. [**Prometheus-operator & Grafana**](docs/kubernetes/features/metrics.md) for standardized metrics and visualization tool.
3. [**ELK Stack**](docs/kubernetes/features/logging.md) for logging, tracing, and visualization.
4. [**Rook Ceph**](docs/kubernetes/features/persistent_storage.md) for transparent provisioning of persistent/distributed storage. Also for as-need creation of S3 storage.
5. [**Ingress**](docs/kubernetes/features/ingress_loadbalancing.md) for transparent loadbalancing.
6. **Simple storage service** for a simple API for storing and sharing products between microservices. (coming soon)
7. **API gateway** for securing acccess to microservice api's and enforcing a standard authentication mechanism. (coming soon)
8. **Cluster Dashboard** for admins to inspect and manage their services using a UI. (coming soon)
9. **Auto scaling** for increasing available instances as application load increases. (coming soon)

## Docker Swarm (legacy)

To deploy as a Docker swarm, follow the instructions in the [Swarm deployment guide](docs/swarm/Swarm_deploy_guide.md)

## Grayskull platform services on Docker Swarm
TODO

## Design

Each implementation of Project Grayskull consists of three distinct portions, for specific instructions see the corresponding guide for the versions below.

#### Deploying nodes

The Project Grayskull platform provides functionality within an orchestration engine (Kubernetes). Kubernetes in turn runs on a series of servers, either as virtual machines or bare metal. The nodes are these servers; each guide includes instructions on how to deploy VMs using Hashicorp's [Terraform](https://www.terraform.io/).

#### Orchestrator

Running on top of these nodes is [Kubernetes](https://kubernetes.io/), a robust container orchestrator. Its job is to run the applications of Project Grayskull, providing platform services, monitoring application health, and much more.

#### Platform

The Project Grayskull platform is the collection of services that microservices can rely on, and transparently utilize to do the things that fall outside the scope of their application. This includes scaling of applications, collection of metrics and logs, authentication and more. 
