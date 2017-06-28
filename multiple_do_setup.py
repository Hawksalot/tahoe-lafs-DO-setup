from os import environ
from digitalocean import Droplet, Manager

servers = 10
name = test
doToken = os.environ['TOKEN']
doImage = os.environ['DROPLET_ID']
regions = ['nyc1', 'nyc2', 'nyc3', 'sfo1', 'sfo2', 'ams2', 'ams3', 'tor1', 'fra1', 'blr1']
dropletNames = []

for i in range(servers):
    dropletNames[i] = "tStore " + name + "-" + regions[i]

sea = Droplet.create_multiple(token = doToken,
                              names = [dropletNames],
                              size = '512mb',
                              image = doImage,
                              
