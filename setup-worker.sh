#!/bin/bash
 
set -e
 
export DEBIAN_FRONTEND=noninteractive
wget -qO- https://get.docker.io/gpg | apt-key add -
 
echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update
 
apt-get install -y linux-image-extra-`uname -r` lxc lxc-docker-1.0.0
 
docker pull quay.io/travisci/te-worker
docker tag quay.io/travisci/te-worker te-worker
docker pull quay.io/travisci/travis
 
for lang in $(docker images | grep quay.io/travisci/travis | awk '{ print $2 }'); do 
  docker tag quay.io/travisci/travis:$lang travis:$lang 
done
 
# run the install script 
docker run --rm te-worker cat /usr/local/travis/src/host.sh | bash
te start

# use LXC, and disable inter-container communication
echo 'DOCKER_OPTS="-d -e lxc --icc=false"' >> /etc/default/docker

# enable memory and swap accounting (optional, but recommended)
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/' /etc/default/grub

# set permissions for travis.yml, everyone needs to be able to read it
reboot
