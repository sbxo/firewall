#crontab
#* * * * * bash nginx-403-ipset-block.sh

MYIPA=`ip a | grep "inet " | grep "dynamic" | awk '{print $2}' | cut -d "/" -f 1`
sorted=`cat /var/log/nginx/error.log | grep "forbidden" | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort -u`
for x in $sorted
do
  totalip=`cat /var/log/nginx/error.log | grep "forbidden" | grep $x | wc -l`
  if [ $totalip -gt 9 ]
  then
   echo "$x $totalip gt 9, adding to blocklist for 3h"
   ipset -q -exist add blocklist $x timout 10800
  fi
done
mv /var/log/nginx/error.log /var/log/nginx/error.log.old
