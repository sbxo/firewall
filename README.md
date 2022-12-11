# What is it?
**tldr:** iptables that blocks all traffic except for white listed ip sets/ranges. includes blocklist if you want to comment out the whitelist denies.

IPTABLES FIREWALL


# Whitelisted IP addresses
For development servers, or servers where it can add the IP addresses from a db for better traffic shaping.
This will scan for all connected users on web, IRC, SSH and afdd them to allow list
This will also get your access logs from nginx, and ssh authorized logins and add them to allow;
This is to avoid complete machine lockout, and allow already known users to still connect to the server's daemons.

To add ip addresses to allow:

``sudo ipset add allow <IP-ADDY> timeout <TIME-IN-SECONDS>``


``bash firewalls.sh``
kernel rules and simple block all, allow only 'allow' ipset

``bash net_resetips.sh``

Clear out all iptables and ipset rules

``bash net_gettor.sh``

Get updated list of TOR-ipaddresses, hut in a silly way; will fix later.

``bash net_blocktor.sh``
Grab IP list of all TOR-IPAddresses.

Add them to ipset list 'block'

``bash net_allowtor.sh``

Grab IP list of all TOR-IPAddresses.

Add them to iptables list allow

``bash net_allow <country> <seconds> 0 for perm``
Block all except country.

``bash net_block <country> <seconds> 0 for perm``
Add country/ipset to block list (overrwides whitelist), it is preferred to remove IP ranges
from the allow instead of block for security reasons.
