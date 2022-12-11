# net_allowtor <secs> 0 for perm
secs="$1"
for n in $(cat ./Tor-IP-Addresses/tor-exit-nodes.lst)
do
 ipset -q add allow $n $secs;
done
