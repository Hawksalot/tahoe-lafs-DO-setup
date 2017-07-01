#! /bin/bash

# temporary hardcoded parameters
# TODO: take NAME and SERVERS as script arguments
NAME=script
SERVERS=10
REGIONS=(nyc1 nyc2 nyc3 sfo1 sfo2 tor1 fra1 blr1 ams2 ams3)

check_node_start ()
{
    while [[ ! $(ssh director@${ADDRESSES[$i]} "pgrep tahoe" =~ "[0-9]{4}.[0-9]{4}") ]]; do
	echo "reattempting node start"
	ssh director@${ADDRESSES[$i]} "~/.local/bin/tahoe start /app/node"
    done
}

check_node_creation ()
{
    # ends when node is set up on host
    while [[ $(ssh director@${ADDRESSES[$i]} "[ -d /app/node ] && echo exists") != "exists" ]]; do
	echo "reattempting node creation"
	ssh director@${ADDRESSES[$i]} "~/.local/bin/tahoe create-node --port=tcp:28561 --location=tcp:${ADDRESSES[$i]}:28561 --basedir=/app/node --nickname=$NAME.$i --introducer=${INTRODUCERS[0]}"
    done
}

check_intro ()
{
    # ends when introducer is set up and started on host and the furl is stored at an array index
    while [[ ! ${INTRODUCERS[$i]} ]]; do
	echo "reattempting introducer creation and start"
	if [[ $(ssh -o director@${ADDRESSES[$i]} "[ -d /app/introducer] && echo 'exists'" != "exists") ]]; then
	    ssh -o StrictHostKeyChecking=no director@${ADDRESSES[$i]} "~/.local/bin/tahoe create-introducer --port=tcp:12321 --location=tcp:${ADDRESSES[$i]}:12321 --basedir=/app/introducer; ~/.local/bin/tahoe start /app/introducer"
	fi
	INTRODUCERS[$i]=$(ssh director@${ADDRESSES[$i]} "cat /app/introducer/private/introducer.furl")
	while [[ ! $(ssh director@${ADDRESSES[$i]} "pgrep tahoe" =~ "[0-9]{4}") ]]; do
	    ssh director@${ADDRESSES[$i]} "~/.local/bin/tahoe start /app/introducer"
	done
    done
}

check_address ()
{
    # ends when script can retrieve address of host
    while [[ ! ${ADDRESSES[$i]} ]]; do
	echo "reattempting address retrieval"
	ADDRESSES[$i]=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/${NEW_IDS[$i]}" | jq '.droplet.networks.v4[0].ip_address' | tr -d '"')
    done
}

check_id ()
{
    # ends when new host POST request returns successful
    while [[ ! ${NEW_IDS[$i]} ]]; do
	echo "reattempting host launch"
	NEW_IDS[$i]=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$NAME'.'$i'","region":"'${REGIONS[$i]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$NAME'"]}' "https://api.digitalocean.com/v2/droplets" | jq '.droplet.id')
    done
}

# create debug folder and initialize debug file
# MAYBE: just created debug files as $NAME.txt?
mkdir -p ~/tStore/$NAME
cd ~/tStore/$NAME
touch debug.txt
echo "Setting up tStore instance"

# loops through setup of storage nodes, stopping short of setting up introducers file 
for (( i=0; i<$SERVERS; i++ )); do
    # begin debug file 
    echo $i >> debug.txt
    echo "Host $i"
    # launches DigitalOcean droplet
    NEW_IDS[$i]=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"name":"tStore.'$NAME'.'$i'","region":"'${REGIONS[$i]}'","size":"512mb","image":"'$DROPLET_ID'","ssh_keys":["10168822"],"monitoring":"True","tags":["tStore","'$NAME'"]}' "https://api.digitalocean.com/v2/droplets" | jq '.droplet.id')
    if [[ ! ${NEW_IDS[$i]} ]]; then
	check_id
    fi
    #-- debug and visual reference
    echo ${NEW_IDS[$i]} >> debug.txt
    echo "Host launched"

    # waits until droplet is active
    while [[ $(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/${NEW_IDS[$i]}" | jq '.droplet.status') != '"active"' ]]; do
	echo "Host not fully up yet"
	sleep 30s
    done

    # stores IP address of droplet
    ADDRESSES[$i]=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/${NEW_IDS[$i]}" | jq '.droplet.networks.v4[0].ip_address' | tr -d '"')
    if [[ ! ${ADDRESSES[$i]} ]]; then
	check_address
    fi
    #-- debug and visual reference
    echo ${ADDRESSES[$i]} >> debug.txt
    echo "Address retrieved"

    # creates and starts Tahoe-LAFS introducer then stores furl
    ssh -o StrictHostKeyChecking=no director@${ADDRESSES[$i]} "~/.local/bin/tahoe create-introducer --port=tcp:12321 --location=tcp:${ADDRESSES[$i]}:12321 --basedir=/app/introducer; ~/.local/bin/tahoe start /app/introducer"
    INTRODUCERS[$i]=$(ssh -o StrictHostKeyChecking=no director@${ADDRESSES[$i]} "cat /app/introducer/private/introducer.furl")
    if [[ ! ${INTRODUCERS[$i]} ]]; then
	check_intro
    fi
    #-- debug and visual reference
    echo ${INTRODUCERS[$i]} >> debug.txt
    echo "Introducer started"
    
    # creates Tahoe-LAFS node
    ssh director@${ADDRESSES[$i]} "~/.local/bin/tahoe create-node --port=tcp:28561 --location=tcp:${ADDRESSES[$i]}:28561 --basedir=/app/node --nickname=$NAME.$i --introducer=${INTRODUCERS[0]}"
    if [[ $(ssh director@${ADDRESSES[$i]} "[ -d /app/node ] && echo 'exists'" != "exists") ]]; then
	check_node_creation
    fi
done

# creates complete introducer list on each storage node server and starts node
for (( x=0; x<$SERVERS; x++ )); do
    # first line of introducers.yaml
    ssh director@${ADDRESSES[$x]} "echo 'introducers:' >> /app/node/private/introducers.yaml"
    # loops through formatted introducer fURLs
    for (( y=1; y<$SERVERS; y++ )); do
	ssh director@${ADDRESSES[$x]} "echo '  intro$y:
    furl: ${INTRODUCERS[$y]}' >> /app/node/private/introducers.yaml"
    done
    # starts Tahoe-LAFS node
    ssh director@${ADDRESSES[$x]} "~/.local/bin/tahoe start /app/node"
    if [[ ! $(ssh director@${ADDRESSES[$x]} "[ pgrep tahoe ]" =~ "[0-9]{4}.[0-9]{4}") ]]; then
	check_node_start
    fi
done
