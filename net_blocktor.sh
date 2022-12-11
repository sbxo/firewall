# net_blocktor <secs> 0 for perm
secs="$1"
for n in $(cat ./Tor-IP-Addresses/tor-exit-nodes.lst)
do
 ipset -q del block $n
 ipset -q add allow $n timeout $secs
done
