Installing Travis CI Enterprise
===============================

**Please email enterprise@travis-ci.com for more information on pricing and to register for a 45 day trial.**

## Prerequisites

- Two dedicated hosts or hypervisors (VMWare, OpenStack using KVM, or EC2) with Ubuntu 14.04 installed
- A Travis CI Enterprise license file
- A GitHub Enterprise OAuth app


## Host Machines

The standard setup consists of two hosts, the Travis CI Enterprise platform server which hosts the web UI and 
related services, and one or more Worker hosts which run the tests/jobs in isolated containers using LXC and Docker.

If you are using EC2 then we recommend the **c3.2xlarge** instance type.

Otherwise we recommend hosts with 16 gigs of RAM and 8 CPUs.



## Register a GitHub OAuth app

Travis CI talks to GitHub Enterprise via OAuth. You will need to create an OAuth app 
on your GitHub Enterprise which Travis CI Enterprise can connect to.

The OAuth app registered will use the domain name pointing to your Platform host for 
the Homepage URL (e.g. https://travis-ci.your-domain.com). Append /api to this for 
the Authorization callback URL (e.g. https://travis-ci.your-domain.com/api).



## Installation

### Setting up the Travis CI Enterprise Platform

The recommended installation of the Platform host is done through running the following script on the host:

`curl -sSL https://enterprise.travis-ci.com/install | sudo sh`

(We recommend downloading the reading the script before running it)

This will install the management application, which takes care of downloading and installing the Travis CI Platform, as well as providing a simple web interface for setting up the platform, and for viewing runtime metrics.

Once the script has run you can navigate to http://<hostname>:8800 to complete the setup.

From here you can upload your trial license key, add your GitHub OAuth details, and upload an SSL certificate or enter SMTP details (both optional).

If you are running the Platform host on EC2, we recommend using an image which uses EBS for the root volume, as well as allocating 30 gigs of space to it. It is also recommended to not destroy the volume on instance termination.

If you are behind a web proxy and Docker fails to download the image(s), please edit ```/etc/default/docker``` and set your proxy there.
```
...
# If you need Docker to use an HTTP proxy, it can also be specified here.
export http_proxy="http://proxy.mycompany.corp:8080/"
...
```


### Setting up a Travis CI Enterprise Worker

For setting up a Worker host you'll need the RabbitMQ password, which you can find from the Travis CI Enterprise Platform management UI.

Before running the following commands, please make sure you are logged in as as user who has access to sudo.

If the Worker host is running on EC2 please run the following command:

```
curl -R https://raw.githubusercontent.com/travis-ci/enterprise-installation/master/setup-worker.sh | sudo AWS=true bash
```

Otherwise run:

```
curl -R https://raw.githubusercontent.com/travis-ci/enterprise-installation/master/setup-worker.sh | sudo bash
```

If you are behind a web proxy and Docker fails to download the image(s), edit ```/etc/default/docker``` and set your proxy there. Re-run the script above.
```
...
# If you need Docker to use an HTTP proxy, it can also be specified here.
export http_proxy="http://proxy.mycompany.corp:8080/"
...
```

It is highly recommended to reboot you host after completing the installaion.



## Maintenance

### Updating your Travis CI Enterprise Platform

### Updating your Travis CI Enterprise Worker

In order to update the Docker images and restart the Worker you can run the following on each worker host:

```
te pull
te start
```


### Inspecting logs and running services

On both hosts the logs are located at /var/travis/log/travis.log, but also symlinked to /var/log/travis.log for convenience.



### Reconfiguring the container

To re-enter or change your worker configuration, please run:

```
te configure --prompt
```

Then restart the container:

```
te start
```

### Configuring your worker installation with advanced options

During normal install you'll be asked to provide a few required configuration
settings, however there are more configuration settings that can be specified.

The following configuration groups are currently available:

```
rabbitmq - RabbitMQ configuration options
s3       - S3 bucket credentials for dependency caching
worker   - number of VMs to be used
```

eg. 

```
te configure --group worker
```



### Starting a build container on the worker host

In order to start a build container on the Travis CI Enterprise worker host you can do the following:

```
# start a container and grab the port
id=$(docker run -d -p 22 travis:php /sbin/init)
port=$(docker port $id 22 | sed 's/.*://')

# ssh into the container (the default password is travis)
ssh travis@localhost -p $port

# stop and remove the container
docker kill $id
docker rm $id
```

### Customizing build images

Once you have pulled the build images from quay.io, and they've been re-tagged to `travis:[language]` you can fully customize these images according to your needs.

Be aware that you'll need to re-apply your customizations after upgrading build images from quay.io.

The basic idea is to:

* start a Docker container based on one of the default build images `travis:[language]`,
* run your customizations inside that container, and
* commit the container to a Docker image with the original `travis:language` name (tag).

For example, in order to install a particular Ruby version which is not available on the default `travis:ruby` image, and make it persistent, you can run:

```
docker run -it --name travis_ruby travis:ruby su travis -l -c 'rvm install [version]'
docker commit travis_ruby travis:ruby
```

