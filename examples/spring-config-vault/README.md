# Spring Simple
### Config Server/Client + Vault
This app contains a vault server with a secret representing some config. There is a Config Server which can access the 
config and serve it to apps that needs it. Finally there is a Config Client that queries the Config server both at 
startup. This Client consumes the secret.

This version is a simple spring set up. It includes the minimum needed to use config server/client, where all of the
authentication and sharing is hardcoded. Use proper authentication on the config server and on vault, including non-root
tokens when building for production.

## How to use this

##### Steps

Build the docker images using `make`
```
> make 
```

Run the docker stack:
```
> docker stack deploy -c docker-stack.yaml vault
Creating service vault_vault-stk
Creating service vault_spring-svr-stk
Creating service vault_spring-client-stk

```

Next unseal the vault, you'll have to get into the vault container to do this.
Vault credentials by default are
```
vault credentials are:
key: uEx4QJSS5kozP5CKxd387JsTacuxnnusgI8D88Cr0RI=
root_token: s.aCFDJYAxoJgV4K1rh4RlkxQa
```
```
> docker ps
CONTAINER ID        IMAGE                  
f28392e1925a        spring-client:latest   
b5aa6977e5cf        spring-svr:latest 
a1b74c0eff08        vault:latest

> docker exec -it a1b sh

/# vault operator unseal uEx4QJSS5kozP5CKxd387JsTacuxnnusgI8D88Cr0RI=
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.0.3
Cluster Name    vault-cluster-7b180b7d
Cluster ID      f71969a6-bd45-e3d5-37a6-9b3f26bc0e5f
HA Enabled      false

/# exit
```


Now ask the client for the secret config value it fetched from vault. If there is an error trying stopping and restarting the client.
```
>  curl -X GET 127.0.0.1:8080/getsecret
Hello! we retrieved value startpropertyvalue
```

To delete it:
```
> docker service rm vault_spring-client-stk vault_spring-svr-stk vault_vault-stk
vault_spring-client-stk
vault_spring-svr-stk
vault_vault-stk
```

### Process Explanation

Vault contains a secret at the path "secret/democlient" with the value of `startproperty="startpropertyvalue"`.

Spring cloud config populates values to properties with the `@Value` annonation when the containing app is started.
A cloud config server talks to Vault (in this case), to get configs when they are requested. 

The cloud config client will start and try to fetch the value of `${startproperty}` from the cloud config server 
specified in the `bootstrap.yaml`.
```
config:
    uri: http://spring-svr-stk:8888
    token: s.aCFDJYAxoJgV4K1rh4RlkxQa
    username: user
    password: secret
    fail-fast: false
```

If it fails because the server is unavailable (still starting for example), the `fail-fast` annonation will cause an exception to be thrown,
ending the client container. Docker will restart the container and if the server is now available. It sends a request to
the server at the `/democlient/default` endpoint, representing its profile. The server responds with the value it 
retrieves from Vault. 

It only does this once, when the app starts, so any changes to the config will not be reflected 
unless the app is refreshed or restarted.


### If Vault's data folder gets deleted
Vault credentials are:
```
key: uEx4QJSS5kozP5CKxd387JsTacuxnnusgI8D88Cr0RI=
root_token: s.aCFDJYAxoJgV4K1rh4RlkxQa
```

If you deleted the data folder, you will have to `docker exec` into the vault container like you would to unseal it.
```
/# vault init
```
Copy the key and root_token.
```
/# vault operator unseal
/# vault login <root_token>
```
Copy the root token into `./demo_client/demo_client/src/main/resources/bootstrap.yaml:token`

run `make`, start using `docker stack`, and unseal the vault as above.
    
    
#### Misc
For debugging from client container:
`wget --header "X-Config-Token: s.aCFDJYAxoJgV4K1rh4RlkxQa" http://spring-svr-stk:8888/democlient/default`
    