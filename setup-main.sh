#!/bin/bash
 
set -e
 
export DEBIAN_FRONTEND=noninteractive
wget -qO- https://get.docker.io/gpg | apt-key add -
 
echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update
 
apt-get install -y linux-image-extra-`uname -r` lxc lxc-docker-1.0.0

if [[ $AWS ]]; then
  DOCKER_MOUNT_POINT="--graph=/mnt/docker"
fi

# use LXC, and disable inter-container communication
echo 'DOCKER_OPTS="-d --exec-driver=lxc $DOCKER_MOUNT_POINT"' >> /etc/default/docker

service docker restart
# pull the images
docker pull quay.io/travisci/te-main
docker tag quay.io/travisci/te-main te-main
 
# run the install script
docker run --rm te-main cat /usr/local/travis/src/host.sh | bash
te start
 
# set permissions for travis.yml, everyone needs to be able to read it
chmod a+r /etc/travis/license.yml
 
# grab the generated rabbitmq password, you'll need it for setting up the worker box:
grep RABBITMQ /etc/travis/env.sh | sed 's/.*=//'
