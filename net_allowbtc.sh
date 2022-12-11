wget https://raw.githubusercontent.com/bitcoin/bitcoin/master/contrib/seeds/nodes_main.txt && cat nodes_main.txt | grep "AS" | cut -d " " -f 1 | tr -d ":8333" > ./btc.list
secs="0"
for n in $(cat btc.list)
do
  #0 = forever
  #3days = 259200
  #7days = 604800
  ipset -q -exist add allow $n timeout $secs
done
