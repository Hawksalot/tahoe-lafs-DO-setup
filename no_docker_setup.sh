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

SERVERS=10
NAME=test
REGIONS=(nyc1 nyc2 nyc3 sfo1 sfo2 tor1 fra1 ams2 ams3 sgp1)

for (( i=0; i<=$SERVERS; i++ ))
do
    echo $NAME
    echo $i
    echo ${REGIONS[$i]}
    echo $DROPLET_ID
    curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$NAME'.'$i'","region":"'${REGIONS[$i]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$NAME'"]}' "https://api.digitalocean.com/v2/droplets"
done

for (( i=0; i<=$SERVERS; i++ ))
do
    ADDRESSES[$i-1]=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets?tag_name=$NAME" | jq '.droplets['$i'].networks.v4[0].ip_address')
done

