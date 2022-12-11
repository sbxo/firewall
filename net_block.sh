# 2 weeks in seconds = 1209600, use 0 for permnanent.
# ./net_block COUNTRY SECONDS
secs="$2"
rm $1.zone
wget -q http://www.ipdeny.com/ipblocks/data/countries/$1.zone
for x in $(cat $1.zone ); do ipset -q add block $x $secs; done
