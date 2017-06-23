#!/bin/bash

#while getopts h:s:n: option
#do
#    case "${option}"
#	in
#	h) SHARES=${OPTARG};;
#	s) SERVERS=${OPTARG};;
#	n) NAME=${OPTARG};;
#    esac
#done

# temporary hardcoded variables
SERVERS=10
NAME=test

REGIONS=(nyc1 nyc2 nyc3 sfo1 sfo2 tor1 fra1 ams2 ams3 blr1)

for (( i=0; i<=$SERVERS; i++ ))
do
    curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$NAME'.'$i'","region":"'${REGIONS[$i]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$NAME'"]}' "https://api.digitalocean.com/v2/droplets"
done

for (( i=0; i<=$SERVERS; i++ ))
do
    until [ -a $(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets?tag_name=$NAME" | jq '.droplets['$i'].networks.v4[0].ip_address') ];
    do
          sleep 1m
    done
    ADDRESSES[$i]=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets?tag_name=$NAME" | jq '.droplets['$i'].networks.v4[0].ip_address')

done

for (( i=0; i<=$SERVERS; i++ ))
do
    ssh root@${ADDRESSES[$i]}
    su director
    cd /app
    tahoe create-introducer --port=tcp:12321 --location=tcp:${ADDRESSES[$i]}:12321 --basedir=app/introducer
    tahoe start introducer
    INTRODUCERS[$i]=$(cat /app/introducer/private/introducer.furl)
    tahoe create-node --port=tcp:3457 --location=tcp:${ADDRESSES[$i]}:3457 --basedir=/app/node --nickname=$NAME.$i --introducer=${INTRODUCERS[0]}
done

for (( i=0; i<=$SERVERS; i++ ))
do
    ssh root@${ADDRESSES[$i]}
    su director
    cd /app/node/private
    echo "introducers:" >> introducers.yaml
    for (( n=2; n<=$SERVERS; n++ ))
    do
        echo "  intro$n:
                  furl: ${INTRODUCERS[$n-1]}" >> introducers.yaml
    done
    cd /app
    tahoe start node
done
