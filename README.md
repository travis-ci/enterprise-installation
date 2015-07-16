Installing Travis CI Enterprise
===============================

**Please email enterprise@travis-ci.com for more information on pricing and to register for a 45 day trial.**

## Prerequisites

- Two dedicated hosts or hypervisors (VMWare, OpenStack using KVM, or EC2) with Ubuntu 14.04 installed
- A Travis CI Enterprise license file
- A GitHub Enterprise OAuth app


## Host Machines

The standard setup consists of two hosts, the Travis CI Enterprise Platform which hosts the web UI and related services, and one or more Worker hosts which run the tests/jobs in isolated containers using LXC and Docker.

If you are using EC2 then we recommend the **c3.2xlarge** instance types.

For other setups we recommend hosts with 16 gigs of RAM and 8 CPUs.


## Register a GitHub OAuth app

Travis CI Enterprise talks to GitHub Enterprise via OAuth. You will need to create an OAuth app on your GitHub Enterprise which Travis CI Enterprise can connect to.

The OAuth app registered will use the domain name pointing to your Platform host for  the Homepage URL (e.g. https://travis-ci.your-domain.com). Append /api to this for the Authorization callback URL (e.g. https://travis-ci.your-domain.com/api).


## Installation

### Setting up the Travis CI Enterprise Platform

The recommended installation of the Platform host is done through running the following script on the host:

```bash
curl -sSL -o /tmp/installer.sh https://enterprise.travis-ci.com/install
sudo bash /tmp/installer.sh
```

(We recommend downloading and reading the script before running it)

This will install the management application, which takes care of downloading and installing the Travis CI Platform, as well as providing a simple web interface for setting up the platform, and for viewing runtime metrics.

Once the script has run you can navigate to `https://<hostname>:8800` to complete the setup.

From here you can upload your trial license key, add your GitHub OAuth details, and upload an SSL certificate or enter SMTP details (both optional).

If you are running the Platform host on EC2, we recommend using an image which uses EBS for the root volume, as well as allocating 30 gigs of space to it. It is also recommended to not destroy the volume on instance termination.

If you are behind a web proxy you can run the following install commands:
```bash
curl -sSL -x http://<proxy>:<port> -o /tmp/installer.sh https://enterprise.travis-ci.com/install
sudo bash /tmp/installer.sh http-proxy=http://<proxy>:<port>
```


### Setting up a Travis CI Enterprise Worker

For setting up a Worker host you'll need the RabbitMQ password, which you can find from the Travis CI Enterprise Platform management UI.

Before running the following commands, please make sure you are logged in as as user who has access to sudo.

```bash
curl -sSL https://enterprise.travis-ci.com/install/worker -o /tmp/installer
```

If the Worker host is running on EC2 please run the following command:

```bash
sudo bash /tmp/installer \
 --travis_enterprise_host="travis.myhostname.com" \
 --travis_enterprise_security_token="my-rabbitmq-password"` \
 --aws=true
```

Otherwise run:

```bash
sudo bash /tmp/installer \
 --travis_enterprise_host="travis.myhostname.com" \
 --travis_enterprise_security_token="my-rabbitmq-password"`
```

If you are behind a web proxy and Docker fails to download the image(s), edit ```/etc/default/docker``` and set your proxy there. Re-run the script above.

```bash
...
# If you need Docker to use an HTTP proxy, it can also be specified here.
export http_proxy="http://proxy.mycompany.corp:8080/"
...
```

It is highly recommended to reboot you host after completing the installaion.


## Maintenance

### Updating your Travis CI Enterprise Platform

You can check for new releases by going to the management interface dashboard (`https://<hostname>:8800`) and clicking on the 'Check Now' button. If an update is available you will be able to read the release notes and install the update.

It is also recommended to run the following commands on the Platform host afterwards:

```
sudo apt-get update
sudo apt-get install replicated replicated-ui replicated-agent replicated-updater
```


### Updating your Travis CI Enterprise Worker

In order to update the Worker, you can run the following on each worker host:

```
sudo apt-get update
sudo apt-get install travis-worker
```


### Stopping and Starting the Worker

The Travis CI Worker is installed as an upstart service. The following commands can be used to check the status of the service, and to start or stop it.

```bash
$ sudo status travis-worker
travis-worker start/running, process 9622

$ sudo stop travis-worker
travis-worker stop/waiting

$ sudo start travis-worker
travis-worker start/running, process 16339
```

### Inspecting logs and running services

On the Platform you can find the main log file at `/var/travis/log/travis.log`. They are also symlinked to `/var/log/travis.log` for convenience.

On the Worker you can find the main log file at `/var/log/upstart/travis-worker.log`


### Options for customizing the Worker

The following options can be customized in `/etc/default/travis-worker`. It is recommended to have all Workers use the same config.

By default Jobs can run for a maximum of 50 minutes. You can increase, or decrease, this using the following setting:
```bash
TRAVIS_WORKER_HARD_TIMEOUT="50m"
```

If no log output has been received over 10mins the job is cancelled as it is assumed the job stalled. You can customize this timeout using the following setting:
```bash
TRAVIS_WORKER_LOG_TIMEOUT="10m"
```

This allows you to customize how many jobs are run by the worker. Each Worker runs 2 Jobs by default. Each Job requires 2 CPU cores, so if your host has only 4 cores and you set this to `3`, you will see errors in the Worker logs. Please do not set this to be higher than CPU cores divided by 2.
```bash
TRAVIS_WORKER_POOL_SIZE="2"
```

Each Worker should have a unique hostname, making it easier to determine where jabs ran. By default this is set to the `hostname` of the host the Worker is running on.
```bash
TRAVIS_WORKER_HOSTNAME="<hostname>"
```

The Platform comes setup with a self signed SSL certificate, this option allows the Worker to talk to the Platform via SSL but ignore the verification warnings.
```bash
TRAVIS_WORKER_BUILD_API_INSECURE_SKIP_VERIFY="false"
```

If you would like to setup S3 dependency caching for your builds, you can use the following example config:
```bash
TRAVIS_WORKER_BUILD_CACHE_FETCH_TIMEOUT="600"
TRAVIS_WORKER_BUILD_CACHE_PUSH_TIMEOUT="3000"
TRAVIS_WORKER_BUILD_CACHE_S3_ACCESS_KEY_ID="<access_key_id>"
TRAVIS_WORKER_BUILD_CACHE_S3_SECRET_ACCESS_KEY="<secret_access_key>"
TRAVIS_WORKER_BUILD_CACHE_S3_BUCKET="<caching_bucket>"
TRAVIS_WORKER_BUILD_CACHE_S3_REGION="us-east-1"
TRAVIS_WORKER_BUILD_CACHE_S3_SCHEME="https"
TRAVIS_WORKER_BUILD_CACHE_TYPE="s3"
```


### Adding a custom root SSL certificate to the Platform

If your GitHub Enterprise instance uses a special (e.g. self-signed) root certificate, then you will want to import this to your Platform instance so it can connect via SSL.

In order to provide a root certificate you can place it in ```/etc/travis/ssl/ca-certificates```, for example:

```
/etc/travis/ssl/ca-certificates/some-name.crt
```

Then restart the Platform by loggin into the Management UI and stopping, and then starting, Travis CI Enterprise.

During startup all certificate files in this directory will be symlinked to ```/usr/shared/ca-certificates``` and ```/usr/local/shared/ca-certificates``` and ```update-ca-certificates``` will be run.


### Starting a build container on the worker host (debug containers)

In order to start a build container on a Travis CI Enterprise Worker host you can do the following:

```
# start a container and grab the port
id=$(docker run -H tcp://0.0.0.0:4243 -d -p 22 travis:php /sbin/init)
port=$(docker port -H tcp://0.0.0.0:4243 $id 22 | sed 's/.*://')

# ssh into the container (the default password is travis)
ssh travis@localhost -p $port

# stop and remove the container
docker kill -H tcp://0.0.0.0:4243 $id
docker rm -H tcp://0.0.0.0:4243 $id
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
docker run -H tcp://0.0.0.0:4243 -it --name travis_ruby travis:ruby su travis -l -c 'rvm install [version]'
docker commit -H tcp://0.0.0.0:4243 travis_ruby travis:ruby
```

