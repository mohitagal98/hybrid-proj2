#!/bin/bash
sudo su - root

#installing and starting docker service
yum install docker -y
service docker start
chkconfig docker on

#downloading docker-compose
curl -L https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Installing AWS EFS Utilities
yum install amazon-efs-utils -y

mkdir /storage

#Mounting EFS
mount -t efs "${efs_id}":/ /storage

#Editing fstab so that EFS loads automatically on reboot
echo "${efs_id}":/ /storage efs defaults,_netdev 0 0 >> /etc/fstab
mkdir /storage/sqlstorage
mkdir /storage/phpstorage
rm -rf /storage/phpstorage/*

# Cloning git repo into storage
yum install git -y
git clone https://github.com/mohitagal98/hybrid-proj1.git
cp -rf hybrid-proj1/* /storage/phpstorage
cp -f hybrid-proj1/docker-compose.yml /root/

#Launching environment using docker-compose
docker-compose up