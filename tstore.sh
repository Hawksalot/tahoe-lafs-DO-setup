#! /bin/bash

NAME=script
SERVERS=10
REGIONS=(nyc1 nyc2 nyc3 sfo1 sfo2 tor1 fra1 blr1 ams2 ams3)

mkdir -p ~/tStore/$NAME
cd ~/tStore/$NAME
#echo "introducers:" >> introducers.yaml
#echo "servers:" >> servers.txt


for (( i=0; i<$SERVERS; i++ )); do
    NEW_ID=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$NAME'.'$i'","region":"'${REGIONS[$i]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$NAME'"]}' "https://api.digitalocean.com/v2/droplets" | jq '.droplet.id')
    
    echo "Droplet created"

    while [[ $(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/$NEW_ID" | jq '.droplet.status') != '"active"' ]]; do
	echo $(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/$NEW_ID" | jq '.droplet.status')
	echo "try again"
	sleep 30s
    done

    ADDRESS=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/$NEW_ID" | jq '.droplet.networks.v4[0].ip_address' | tr -d '"')
#    echo $ADDRESS >> servers.txt
    echo "Address retrieved"

    ssh -o StrictHostKeyChecking=no director@$ADDRESS "~/.local/bin/tahoe create-introducer --port=tcp:12321 --location=tcp:${ADDRESSES[$i]}:12321 --basedir=/app/introducer; ~/.local/bin/tahoe start /app/introducer"
    INTRODUCERS[$i]=$(ssh -o StrictHostKeyChecking=no director@$ADDRESS "cat /app/introducer/private/introducer.furl")
    ssh -o StrictHostKeyChecking=no director@${ADDRESSES[$i]} "~/.local/bin/tahoe create-node --port=tcp:28561 --location=tcp:${ADDRESSES[$i]}:28561 --basedir=/app/node --nickname=$NAME.$i --introducer=${INTRODUCERS[$i]}"
done

for (( x=0; x<$SERVERS, x++ )); do
    ssh -o StrictHostKeyChecking=no director@${ADDRESSES[$x]} "cat 'introducers:' >> /app/node/private/introducers.yaml"
    for (( y=2; y<=$SERVERS; y++ )); do
	ssh -o StrictHostKeyChecking=no director@${ADDRESSES[x]} "cat '  intro$y:\n    furl: ${INTRODUCERS[$y-1]}' >> introducers.yaml"
    done
    ssh -o StrictHostKeyChecking=no director@${ADDRESSES[$x]} "~/.local/bin/tahoe start /app/node"
done
