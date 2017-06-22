#! /bin/bash
# will set up proof-of-concept instance of tStore

# TODO:these numbers should be input as arguments to this bash script
MANAGERS=1
WORKERS=10

# TODO: this script should take the above numbers as arguments
# TODO: script should create 11 DO droplets from a saved snapshot including Docker installed
# TODO: write this script
python sample_do_setup.py

# TODO:
for i in {1..$WORKERS}
do
    CONNECTIONADDRESS[i]= # bash script that checks for each line in
done
# connects to each worker node, gets introducer fURL, saves to array
for i in {1..$WORKERS}
do
    ssh director@$CONNECTIONADDRESS[i]
    INTROS[i]="cat introducer.furl location"
    sh exit
done

# CHECK: creates and populates introducers list .yaml file
printf "introducers:\n" > introducers.yaml
for i in {1..$WORKERS}
do
    printf "intro"+=$i+=":\n" > introducers.yaml
    printf "furl: "+=$INTROS[i]+="\n" > introducers.yaml
done

# CHECK: copies complete list of introducers to each worker node
for i in {1..$WORKERS}
do
    scp introducers.yaml director@$CONNECTIONADDRESS:~/.tahoe/private/
done
    
# CHECK: init tahoe introducers and storage nodes
for i in {1..$WORKERS}
do
    ssh director@$CONNECTIONADDRESS[i]
    tahoe start .tahoe
    tahoe start .intro
done
