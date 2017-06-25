from requests import get, post
from os import environ
from digitalocean import Droplet, Manager

# temp hardcoded variables
servers = 10
name = test
regions = ["nyc1", "nyc2", "nyc3", "sfo1", "sfo2", "tor1", "fra1", "ams2", "ams3", "blr1"]

token = os.environ['TOKEN']
image = os.environ['DROPLET_ID']

manager = digitalocean.Manager(token=token)
keys = manager.get_all_sshkeys()

for index, region in enumerate(regions):
    newDroplet = digitalocean.Droplet(token=token,
                                      name='tStore' + '-' + name + '-' + i,
                                      region=region,
                                      image=image,
                                      size_slug='512mb',
                                      ssh_keys=keys,
                                      monitoring=True)
    newDroplet.create()
    
