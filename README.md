unifi application with mongodb docker-compose.yml

clone this into a directory

copy env.template to .env

edit .env file and populate variables appropriately

This expects that the unifi controller will run on a dedicated externall defined network with a static IP.  I use an ipvlan network for this, as all of my APs run on a management vlan that doesn't have internet access through the firewall.  Tweak as necessary.

docker compose up -d and enjoy!
