#!/bin/bash
# This script does some basic tasks necessary to bootstrap hosts for use by kubespray later

sudo yum install -y python2 docker

# TODO Replace this with an ami that comes with docker installed
sudo touch /1.txt

#--- Install docker, add the user to the group, and start docker
#sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#sudo yum install -y docker-ce-18.06.3.ce-3.el7
sudo touch /2.txt
#sudo chkconfig docker on
#sudo sed -i -e 's/slave/shared/g' /lib/systemd/system/docker.service
#sudo systemctl daemon-reload
sudo systemctl enable docker
sudo service docker start
#from std image
sudo groupadd docker
sudo usermod -aG docker maintuser
#sudo chgrp docker /lib/systemd/system/docker.socket
#sudo chmod g+w /lib/systemd/system/docker.socket