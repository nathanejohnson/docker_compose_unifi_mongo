## unifi application with mongodb docker-compose.yml that runs on pi3/4

clone this into a directory

copy env.template to .env

edit .env file and populate variables appropriately

This expects that the unifi controller will run on a dedicated externally defined docker network created with

    docker network create


and specify the name of the network created as MANAGEMENT_NETWORK in .env .  This is meant to run with a static IP within the subnet defined in the network, defined as UNIFI_ADDRESS in the .env.  I use an ipvlan network for this, as all of my APs run on a management vlan that doesn't have internet access through the firewall.  Tweak as necessary.


As an example, this is how I created my vlan network for my management netowrk, vlan 2, with 192.168.2.0/24 as the subnet, and 192.168.0.1 as the gateway, and a ipam range of 192.168.2.176-192.168.2.192, hung off interface eth0 vlan 2 (eth0.2) - it will create eth0.2 for you, no need to worry about it existing beforehand.

    docker network create -d ipvlan --gateway 192.168.2.1 --subnet '192.168.2.0/24' --ip-range '192.168.2.176/28' -o 'parent=eth0.2' ipvlan2
    

docker compose up -d and enjoy!


### NOTE: if you're on a raspberry PI, you need to do this in order for ipvlan / macvlan networks to work (assuing ubuntu or likely debian) and reboot:

    apt install linux-modules-extra-raspi
