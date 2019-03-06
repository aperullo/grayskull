# Local Development Initial Setup

There are several steps required to run grayskull locally in development. 
Grayskull is intended to be deployed via docker stacks which require a docker swarm.
For development purposes a single-node swarm may suffice.

## Initialize Local Swarm

To setup a local single-node swarm run `docker swarm init`

Verify no errors occured and check `docker node ls` to verify swarm mode is ready

## Handling Service FQDN

The quick solution is to simply add listings to the hosts file, this will work but requires maintanence over time.

For a more flexible solution see [WildCard DNS](wildcard-dns.md)
