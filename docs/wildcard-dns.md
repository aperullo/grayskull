# Wildcard DNS

Since the loadbalancer utilizes host name matching to route clients to backend services all exposed services have to have resolvable dns listings. Instead of having to create a listing for each service or editing the hosts file for each listing we can use dnsmasq to create a wildcard domain that tranparently redirects all subdomain addresses to a single ip (in this case `127.0.0.1`

## macOS

To set up dnsmasq on macOS do the following:

1. run `brew install dnsmasq`
2. edit `/usr/local/etc/dnsmasq.conf` and add a line for `address=/dev/127.0.0.1`
  * This will create a domain `.dev` which will resolve any subdomain to localhost
  * Works with any depth like `foo.bar.baz.dev`
3. run `sudo brew services enable dnsmasq && sudo brew services start dnsmasq` (sudo is required due to dnsmasq binding port 53
4. run `dig @127.0.0.1 foo.dev` this should respond with a dns match for `foo.dev` pointing at `127.0.0.1`
5. run `sudo mkdir /etc/resolver` this will create a directory for specifying dns resolvers on a per domain basis
6. create a file `/etc/resolver/dev` with and add a line `nameserver 127.0.0.1` (sudo required) this will cause anything in the `dev` domain to use the local dnsmasq service running on `127.0.0.1:53` to resolve dns records
7. run `ping foo.dev` to test that everything is working correctly

Now any service exposed under `.dev` will automatically work (assuming it is running locally)

## Windows

dnsmasq does not run natively on windows so this will require the use of a docker container.
This method also requires changing network interface settings which may need to be reset after development is done

### Setup

1. Get the list of current dns servers in use
2. run `docker container run -d --name dns -p 54:53/udp --cap-add=NET_ADMIN andyshinn/dnsmasq:2.76 --address=/dev/127.0.0.1 --server=<original_dns_server>`
3. Reconfigure network interface to use a custom dns of `127.0.0.1`

### Reset

1. Remove the DNS override from the network interface
2. run `docker rm -f dns`


## Linux

This will depend on the distribution and how the networking is configured.
Check documentation for your distro on how to enable dnsmasq support.

NetworkManager contains plugins to use dnsmasq internally as a chaching layer which can be extended to supply wildcard domains

If the distro uses `systemd-resolved` this is incompatible. To use dnsmasq, systemd-resolved must be replaced with another solution (dnsmasq could replace it via plugins with NetworkManager)