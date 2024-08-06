## unifi application with mongodb docker-compose.yml that runs on pi3/4

clone this into a directory

copy env.template to .env

edit .env file and populate variables appropriately

This expects that the unifi controller will run on a dedicated externally defined docker network created with

    docker network create


and specify the name of the network created as MANAGEMENT_NETWORK in .env .  This is meant to run with a static IP within the subnet defined in the network, defined as UNIFI_ADDRESS in the .env.  I use an ipvlan network for this, as all of my APs run on a management vlan that doesn't have internet access through the firewall.  Tweak as necessary.

docker compose up -d and enjoy!


### NOTE: if you're on a raspberry PI, you need to do this in order for ipvlan / macvlan networks to work (assuing ubuntu or likely debian):

    apt install linux-modules-extra-raspi
