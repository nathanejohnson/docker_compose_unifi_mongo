## unifi application with mongodb docker-compose.yml that runs on pi3/4/5

clone this into a directory

copy env.template to .env

edit .env file and populate variables appropriately

This expects that the unifi controller will run on a dedicated externally defined docker network created with

    docker network create

and specify the name of the network created as `MANAGEMENT_NETWORK` in .env .  This is meant to run with a static IP within the subnet defined in the network, defined as `UNIFI_ADDRESS` in the .env.  I use an ipvlan network for this, as all of my APs run on a management vlan that doesn't have internet access through the firewall.  Tweak as necessary.  You'll also want the user id and group id to be accurate for the `PUID` and `PGID` fields, using values from the `id` command.


As an example, this is how I created my vlan network for my management network, vlan 2, with 192.168.2.0/24 as the subnet, and 192.168.2.1 as the gateway, and a ipam range of 192.168.2.176-192.168.2.192, hung off interface eth0 vlan 2 (eth0.2) - it will create eth0.2 for you, no need to worry about it existing beforehand.  I have a dhcp server on this same vlan, but I make sure both the --ip-range specified as well as the `UNIFI_ADDRESS` are outside of this range, for obvious reasons.  `UNIFI_ADDRESS` should also be outside of the --ip-range specified.

    docker network create -d ipvlan --gateway 192.168.2.1 --subnet '192.168.2.0/24' --ip-range '192.168.2.176/28' -o 'parent=eth0.2' ipvlan2


docker compose up -d and enjoy!


Included also is an [acme.sh](https://github.com/acmesh-official/acme.sh) [deploy hook](unifi_docker.sh) meant to be run on the docker host without requiring the docker container to have network access, and without requiring the docker host to have a jdk / keytool installed.  This allows us to use zerossl / letsencrypt to generate TLS certificates for our web UI.

In order to use the deploy hook, you'll need to symlink this script into place, as an example when running from the base directory of this repository:

    ln -s $(pwd)/unifi_docker.sh ~/.acme.sh/deploy/

And you'll need to initially set the environment variable `UNIFI_DOCKER_DIR` to the location where you cloned this repository.  If you run the command from the repo root directory, you could do something like so:

    UNIFI_DOCKER_DIR=$(pwd) acme.sh --deploy -d unifi.testorg.com --deploy-hook unifi_docker

If this variable isn't set, it will attempt to use `${HOME}/docker_compose_unifi_mongo` if it exists.  Otherwise it will error out.

There are two other variables that can be set:

    UNIFI_HOST_DATA_DIR
if you're moved the unifi data directory volume mount location.  Defaults to `"${UNIFI_DOCKER_DIR}/unifi-data/data"`

    UNIFI_CONTAINER_NAME
if you've changed the name of the unifi container.  Defaults to `unifi-network-application`

This deploy hook saves the state into the acme.sh configuration variables, so it should persist when running subsequently from cron after the initial invocation.
In other words, no need to set these environment variables again after the initial successful invocation.  If something goes wrong, pass the --debug flag to
acme.sh

### NOTE: if you're on a raspberry PI, you need to do this in order for ipvlan / macvlan networks to work (assuing ubuntu or likely debian) and reboot:

    apt install linux-modules-extra-raspi
