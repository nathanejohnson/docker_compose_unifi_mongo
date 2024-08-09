#!/bin/bash

# acme.sh deploy hook, place or symlink into your ${HOME}/.acme.sh/deploy directory

# This allows us to use acme on the docker host without requiring our container to be able
# to get to the public internet for dns challenges, and doesn't require us to have a jdk
# and / or keytool installed locally on the docker host to do the cert / key imports.

#tweak below as necessary

# where you cloned this repo
REPO_DIR=${HOME}/unifi

# the rest are sensible defaults

# this is the directory on your docker host that gets mounted to as the config dir
HOST_DATADIR="${REPO_DIR}/unifi-data/data"

# this is the default set in the docker-compose.yml
UNIFI_CONTAINER=unifi-network-application


# this password is the default keystore passphrase for unifi network application, probably keep that the same.
PASS=aircontrolenterprise

unifi_docker_deploy() {
	_cdomain="$1"
	_ckey="$2"
	_ccert="$3"
	_cca="$4"
	_cfullchain="$5"
	echo running for $_cdomain

	P12="${_cdomain}.p12"
	CNT_DATADIR=/usr/lib/unifi/data
	KEYTOOL=/usr/bin/keytool
	set -e
	openssl pkcs12 -export -inkey "${_ckey}" -in "${_ccert}" \
		-out "${HOST_DATADIR}/${P12}" -name unifi -password pass:${PASS}

	docker exec -it ${UNIFI_CONTAINER} /usr/bin/cp ${CNT_DATADIR}/keystore ${CNT_DATADIR}/keystore.bak
	
	docker exec -it ${UNIFI_CONTAINER} ${KEYTOOL} -delete -alias unifi -keystore ${CNT_DATADIR}/keystore -deststorepass ${PASS} || true
	
	docker exec -it ${UNIFI_CONTAINER} ${KEYTOOL} -importkeystore -deststorepass ${PASS} -destkeypass ${PASS} \
		   -destkeystore ${CNT_DATADIR}/keystore -srckeystore ${CNT_DATADIR}/${P12} \
		   -srcstoretype PKCS12 -srcstorepass ${PASS} -alias unifi -noprompt

	cd ${HOME}/unifi && docker compose restart ${UNIFI_CONTAINER}
}
