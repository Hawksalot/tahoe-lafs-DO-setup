#! /bin/bash

while getopts h:m:n:t: option
do
    case "${option}"
	  in
	      t) TAG=${OPTARG};;
	      n) SHARES=${OPTARG};;
        m) MANAERS=${OPTARG};;
	      h) SERVERS=${OPTARG};;
    esac
done

REGIONS=(nyc1 nyc2 nyc3 sfo1 sfo2 tor1 fra1 ams2 ams3 sgp1) # hard-coded
# creates specified number of swarm worker DO instances across world
for i in {1..$SERVERS}
do
    curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$TAG'.'$i'","region":"'${REGIONS[i-1]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$TAG'"]}' "https://api.digitalocean.com/v2/droplets"
done

# TODO: take in number of manager instances and create for loop
# creates single swarm manager DO instance
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$TAG'.manager","region":"nyc2","size":"512mb","image":"\'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$TAG'"]}' "https://api.digitalocean.com/v2/droplets"

# fills array with node IP addresses
for i in {1..$SERVERS+$MANAGERS}
do
    CONNECTIONS[i-1]=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets?tag_name=$TAG" | jq ".droplets[i-1].networks.v4[0].ip_address")
done

for i in {1..$SERVERS}
do
    ssh root@$CONNECTIONS[i-1]
    docker pull akcipitro/tstore

