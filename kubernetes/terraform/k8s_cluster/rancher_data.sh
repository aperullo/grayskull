#!/bin/bash

#--- set up volumes
# This script does some basic tasks necessary to bootstrap hosts for use by kubespray later
# Tasks:
#   * Expand root volume to use full disk (it initially only uses a small portion)
#   * Install python2 (might be unnecessary)

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk /dev/nvme0n1
  n # new partition
  p # primary partition
    # auto-increment partition number
    # default - start at end of previous partition
    # take remaining free space
  t # edit partion system id
    # grab last partition by default
  8e # Linux LVM
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

sudo partprobe
sudo pvcreate /dev/nvme0n1p3
sudo vgextend VolGroup00 /dev/nvme0n1p3
sudo lvextend -l +100%FREE /dev/mapper/VolGroup00-rootVol
sudo resize2fs /dev/mapper/VolGroup00-rootVol
sudo yum install -y python2

sudo touch /1.txt

#--- Install docker, add the user to the group, and start docker
#sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#sudo yum install -y docker-ce-18.06.3.ce-3.el7
sudo yum install docker -y
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

#--- Relocate where docker stores images for more room
sudo touch /3.txt
#TODO: CURRENTLY TESTING THIS
sudo mkdir -p /storage/docker
sudo service docker stop
sudo mv /var/lib/docker /storage/
ln -s /storage/docker /var/lib/docker

sudo service docker restart

#--- disable fireall and restart docker to clear ip table rules
sudo touch /4.txt
sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo service docker restart

