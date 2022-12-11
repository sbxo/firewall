##flush rules, to clear rules use the ip reset bashscript if you want to restart over and don't want to lock yourself out of ssh
ipset -q flush block
ipset -q flush allow
ipset -q flush block-ip6
ipset -q flush allow-ip6

#make rules
ipset -q create block hash:ip timeout 0
ipset -q create allow hash:ip timeout 0
ipset -q create block-ip6 hash:ip family inet6 timeout 0
ipset -q create allow-ip6 hash:ip family inet6 timeout 0

#kernel rules
sysctl kernel.randomize_va_space=2
sysctl kernel.unprivileged_userns_clone=0
sysctl user.max_user_namespaces=0
sysctl net.ipv6.ip6frag_high_thresh=4194304
sysctl net.ipv6.ip6frag_low_thresh=3145728
sysctl net.ipv6.ip6frag_secret_interval=600
sysctl net.ipv6.ip6frag_time=60
sysctl net.ipv6.route.gc_elasticity=9
sysctl net.ipv6.route.gc_interval=30
sysctl net.ipv6.route.gc_min_interval=0
sysctl net.ipv6.route.gc_min_interval_ms=500
sysctl net.ipv6.route.gc_thresh=1024
sysctl net.ipv6.route.gc_timeout=60
sysctl net.ipv6.conf.all.use_tempaddr=2
sysctl net.ipv6.conf.default.use_tempaddr=2
sysctl net.ipv4.icmp_echo_ignore_broadcasts=1
sysctl net.ipv4.icmp_errors_use_inbound_ifaddr=0
sysctl net.ipv4.icmp_ignore_bogus_error_responses=1
sysctl net.ipv4.icmp_msgs_burst=50
sysctl net.ipv4.icmp_msgs_per_sec=1000
sysctl net.ipv4.icmp_ratelimit=1000
sysctl net.ipv4.icmp_ratemask=6168
sysctl net.ipv4.icmp_echo_ignore_all=1

#allow
#get all the ip-addresses of the successful SSHD logins. Use pubkey auth, and disable password in /etc/ssh/sshd_config
#since sshd gets filesystem and access to memory, turn on host verification.

## DO NOT USE PORTS THAT DO NOT USE ENCRYPTION.

#KNOWNIPDIR="/mnt/rfs/known.ipd" #MOUNTED RAMFS
KNOWNIPFILE="./known.ipd"
cat /var/log/auth.log | grep "Accepted" | awk '{print $11}' | sort -u > $KNOWNIPFILE
ip a | grep "inet " | grep "dynamic" | awk '{print $2}' | cut -d "/" -f 1 | grep -v "::" >> $KNOWNIPFILE

#ircd
ss | grep tcp | grep ":6697" | awk '{print $6}' | cut -d ":" -f 1 | sort -u >> $KNOWNIPFILE

#webd
ss | grep tcp | grep ":443" | awk '{print $6}' | cut -d ":" -f 1 | sort -u >> $KNOWNIPFILE

#mumble
ss | grep tcp | grep ":64738" | awk '{print $6}' | cut -d ":" -f 1 | sort -u >> $KNOWNIPFILE
SSHIPFILE="./ssh.ipd"

#"normal" ssh
ss | grep tcp | grep ":22" | awk '{print $6}' | cut -d ":" -f 1 | sort -u > $SSHIPFILE

#add ssh known auth login ip-addresses to allow indefinitely
for n in $(cat $SSHIPFILE)
do
  ipset -q add allow $n timeout 0
done

#ssh but on port 222
ss | grep tcp | grep ":222" | awk '{print $6}' | cut -d ":" -f 1 | sort -u >> $SSHIPFILE
for n in $(cat $SSHIPFILE)
do
  ipset -q add allow $n timeout 0
done

#compile for temporary ip access listing. 3 days works for what this script was made for by the creator
#use timeout 0 only for small systems and small networks.
grep -rI "." /var/log/nginx/access.log* | cut -d ":" -f 2 | awk '{print $1}' | sort -u >> ./known.ipd

#constantly reupdate another 7 days if IP address is still found/triggers a whitelist
for n in $(cat ./known.ipd)
do
  #3days = 259200
  #7days = 604800
  ipset -q -exist add allow $n timeout 604800
done

#enforce tcp to be used as intended
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

#block everything besides whitelist. blocklist isn't needed but works

#v4
iptables -I INPUT -m set --match-set block src -j DROP
iptables -I INPUT 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I INPUT 2 -m set -j ACCEPT --match-set allow src
iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 2 -m set -j ACCEPT --match-set allow src
iptables -A INPUT -m set ! --match-set allow src -j DROP

#v6
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -I INPUT -m set --match-set block-ip6 src -j DROP
ip6tables -I INPUT 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -I INPUT 2 -m set -j ACCEPT --match-set allow-ip6 src
ip6tables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -I FORWARD 2 -m set -j ACCEPT --match-set allow-ip6 src
ip6tables -A INPUT -m set ! --match-set allow-ip6 src -j DROP

ip6tables -A INPUT -p ipv6-icmp -j DROP
