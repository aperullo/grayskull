# Kubernetes Grayskull

These files are the equivalent deployment files for the resources currently running in docker-swarm.
Some values are hardcoded, and it is not production ready. 

## Instructions

### Pre-requisite
This assumes you have already installed minikube and have kubernetes present.

### Instructions

#### Step 1. Start minikube

```
> minikube start
```

#### Step 2. Edit your DNS
Edit your DNS to redirect all `.kub` to point to the output of `minikube ip`. Note: This will change everytime it starts and is also not suitable for production.

Step 3. Deploy the services.
Deploy each of the files using 
```
> kubectl apply -f ing-con.yml
```
You need to do this for all of the files `ing-con.yml, keycloak.yml, gateway.yml, resource.yml, whoami.yml`

#### To Delete
To delete all the services and cluster you need to run
```
> kubectl delete all -l app=gateway
```
You need to do this command for all of the app labels: `ing, keycloak, mysql, gateway, resource, who`

### Services/Files
`ing-con.yml` - contains the ingress controller/reverse proxy that captures and redirects traffic as needed.
`keycloak.yml` - contains the keycloak and backing mysql database configuration.
`gateway.yml` - contains the deployment for Spring Gateway.
`resource.yml` - contains the deployment for the Resource server.
`whoami.yml` - contains an application for testing ingress connectivity. 

#### Host names
The available host names are:
- `www.key.kub`
- `spring.gateway.kub`
- `www.who.kub`

The others in the file are for other apps to talk to each other. 
