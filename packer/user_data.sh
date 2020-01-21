#!/bin/bash
# This script does some basic tasks necessary to bootstrap hosts for use by kubespray later

sudo yum install -y python2 docker

# TODO Replace this with an ami that comes with docker installed
sudo touch /1.txt

#--- Install docker, add the user to the group, and start docker
sudo touch /2.txt
sudo systemctl enable docker
sudo service docker start
#from std image
sudo groupadd docker
sudo usermod -aG docker maintuser