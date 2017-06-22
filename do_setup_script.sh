#! /bin/bash

while getopts t:n:h: option
do
    case "${option}"
	in
	t) TAG=${OPTARG};;
	n) SHARES=${OPTARG};;
	h) SERVERS=${OPTARG};;
    esac
done

REGIONS=(nyc1 nyc2 nyc3 sfo1 sfo2 tor1 fra1 ams2 ams3 sgp1)
for i in {1..$SERVERS}
do
    D_NAME="tStore $i"
    D_REGION=${REGION[i-1]}
    D_IMAGE=$DROPLET_ID
    curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$TAG'.'$i'","region":"'${REGION[i-1]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":"10168822","monitoring":"True","tags":["tStore","'$TAG'"]}' "https://api.digitalocean.com/v2/droplets"
