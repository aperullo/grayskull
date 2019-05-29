## Minio Server Stack
The minio-server.yml compose file contains a sample stack used to run Minio in distributed mode.

#### Deployment
To run Minio in distributed mode, each server must be deployed on a separate node within a swarm.
Each server is defined as a separate service on the stack. Minio allows between 4 and 16 even number of servers. 

The sample file specifies 4 servers, so at least 4 nodes must be part of the swarm in order to use the sample stack.

Before deploying, the Docker secrets must be set, and each node tagged appropriately.

To set the secrets, run the following on the swarm's manager.

```bash
echo "exampleAccessKey" | docker secret create access_key -
echo "exampleSecretKey" | docker secret create secret_key -
```

To tag the nodes, run the following: 
```bash
docker node update --label-add server1=true <DOCKER-NODE1>
docker node update --label-add server2=true <DOCKER-NODE2>
docker node update --label-add server3=true <DOCKER-NODE3>
docker node update --label-add server4=true <DOCKER-NODE4>
```

To deploy, make sure Traefik proxy is running with a network called `proxy`, then run the following:
```bash
docker stack deploy --compose-file=minio-server.yaml stack_name
```

To ensure the server started successfully, on a web browser, access the object browser that comes embedded with Minio Server. To do so visit the exposed port on any of the nodes:
`http://nodeAddress:9002/minio`

Or with Traefik running, visit `minio.docker.localhost`. 
