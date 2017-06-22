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
