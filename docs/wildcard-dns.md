# Wildcard DNS

Since the load balancer utilizes host name matching to route clients to backend services, all exposed services have to have resolvable DNS listings. Instead of having to create a listing for each service or editing the hosts file for each listing, Dnsmasq can be used to create a wildcard domain that transparently redirects all subdomain addresses to a single ip—in this case `127.0.0.1`.
## macOS

To set up Dnsmasq on macOS do the following:

1. run `brew install dnsmasq`
2. edit `/usr/local/etc/dnsmasq.conf` and add a line for `address=/test/127.0.0.1`
  * This will create a domain `.test` which will resolve any subdomain to localhost
  * Works with any depth like `foo.bar.baz.test`
3. run `sudo brew services enable dnsmasq && sudo brew services start dnsmasq` (sudo is required due to dnsmasq binding port 53
4. run `dig @127.0.0.1 foo.test` this should respond with a dns match for `foo.test` pointing at `127.0.0.1`
5. run `sudo mkdir /etc/resolver` this will create a directory for specifying dns resolvers on a per domain basis
6. create a file `/etc/resolver/test` and add a line `nameserver 127.0.0.1` (sudo required) this will cause anything in the `test` domain to use the local dnsmasq service running on `127.0.0.1:53` to resolve dns records
7. run `ping foo.test` to test that everything is working correctly

Assuming it is running locally, any service exposed under `.test` will now automatically work.

## Windows

Dnsmasq does not run natively on Windows so this will require the use of a Docker container.
This method also requires changing network interface settings which may need to be reset after development is done.

### Setup

1. Get the list of current dns servers in use
2. run `docker container run -d --name dns -p 54:53/tcp -p 54:53/udp --cap-add=NET_ADMIN andyshinn/dnsmasq:2.76 --address=/test/127.0.0.1 --server=/<original_dns_address>/<original_dns_ip>`
3. Reconfigure network interface to use a custom dns of `127.0.0.1`

Note: You can add as many `--address` and `--server` arguments as necessary.

Note to Git Bash users: Git Bash may automatically try to expand the arguments into paths. If this happens, you can disable it by running `export MSYS_NO_PATHCONV=1`

### Reset

1. Remove the DNS override from the network interface
2. run `docker rm -f dns`


## Linux

This will depend on the distribution and how the networking is configured.
Check documentation for your distro on how to enable dnsmasq support.

NetworkManager contains plugins to use dnsmasq internally as a caching layer which can be extended to supply wildcard domains.

If the distro uses `systemd-resolved` this is incompatible. To use dnsmasq, systemd-resolved must be replaced with another solution (dnsmasq could replace it via plugins with NetworkManager).
