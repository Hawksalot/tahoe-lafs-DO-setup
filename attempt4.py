from requests import get, post
from os import environ

# temp hardcoded variables
servers = 10
name = test
regions = ["nyc1", "nyc2", "nyc3", "sfo1", "sfo2", "tor1", "fra1", "ams2", "ams3", "blr1"]

for i in regions:
    
