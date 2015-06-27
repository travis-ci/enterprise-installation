#!/bin/bash
 
set -e
 
export DEBIAN_FRONTEND=noninteractive
wget -qO- https://get.docker.io/gpg | apt-key add -
 
echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update
 
apt-get install -y linux-image-extra-`uname -r` lxc lxc-docker-1.0.0

if [[ $AWS ]]; then
  DOCKER_MOUNT_POINT="--graph=/mnt/docker"
fi

# use LXC, and disable inter-container communication
echo 'DOCKER_OPTS="--icc=false --exec-driver=lxc '$DOCKER_MOUNT_POINT'"' >> /etc/default/docker

service docker restart

sleep 2

docker pull quay.io/travisci/te-worker:latest
docker tag quay.io/travisci/te-worker te-worker

# pick the languages you are interested in
langs='android erlang go haskell jvm node-js perl php python ruby'
tag=latest
for lang in $langs; do
  docker pull quay.io/travisci/travis-$lang:$tag
  docker tag quay.io/travisci/travis-$lang:$tag travis:$lang
done
 
# run the install script 
docker run --rm te-worker cat /usr/local/travis/src/host.sh | bash
te start

# enable memory and swap accounting (optional, but recommended)
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/' /etc/default/grub

echo 'Installation complete.'
echo 'It is recommended that this host is restarted before running jobs through it'
