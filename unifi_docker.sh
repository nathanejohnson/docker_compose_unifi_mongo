#!/bin/bash

# acme.sh deploy hook, place or symlink into your ${HOME}/.acme.sh/deploy directory

# This allows us to use acme on the docker host without requiring our container to be able
# to get to the public internet for dns challenges, and doesn't require us to have a jdk
# and / or keytool installed locally on the docker host to do the cert / key imports.

#tweak below as necessary

# make sure to set UNIFI_DOCKER_DIR to the location where you cloned this repo.
# additionally, you can override the values for UNIFI_HOST_DATA_DIR and UNIFI_CONTAINER
# if needed, though the defaults should work unless you've changed things
# in the docker-compose file.

unifi_docker_deploy() {
	_cdomain="$1"
	_ckey="$2"
	_ccert="$3"
	_cca="$4"
	_cfullchain="$5"
	_debug _cdomain "$_cdomain"
	_debug _ckey "$_ckey"
	_debug _ccert "$_ccert"
	_debug _cca "$_cca"
	_debug _cfullchain "$_cfullchain"

	if ! _exists "docker"; then
		_err "docker not found"
		return 1
	fi

	_getdeployconf UNIFI_DOCKER_DIR
	_default_dcumd="${HOME}/docker_compose_unifi_mongo"
	if [ -z "$UNIFI_DOCKER_DIR" ]; then
		if [ -d ${_default_dcumd} ]; then
			_debug "using ${_default_dcumd} as default UNIFI_DOCKER_DIR"
			UNIFI_DOCKER_DIR="${_default_dcumd}"
		else
			_err "must set UNIFI_DOCKER_DIR environment variable to the directory where the docker_compose_unifi_mongo repository was cloned"
			return 1
		fi
	fi
	_debug "UNIFI_DOCKER_DIR is ${UNIFI_DOCKER_DIR}"

	_getdeployconf UNIFI_HOST_DATA_DIR
	if [ -z "${UNIFI_HOST_DATA_DIR}" ]; then
		UNIFI_HOST_DATA_DIR="${UNIFI_DOCKER_DIR}/unifi-data/data"
	fi
	_debug "UNIFI_HOST_DATA_DIR is $UNIFI_HOST_DATA_DIR"

	_getdeployconf UNIFI_CONTAINER
	if [ -z "${UNIFI_CONTAINER}" ]; then
		UNIFI_CONTAINER=unifi-network-application
	fi

	_debug "UNIFI_CONTAINER is ${UNIFI_CONTAINER}"

	# this password is the default keystore passphrase for unifi network application, probably keep that the same.
	PASS=aircontrolenterprise

	P12="${_cdomain}.p12"
	CNT_DATA_DIR=/usr/lib/unifi/data
	KEYTOOL=/usr/bin/keytool
	HOST_P12="${UNIFI_HOST_DATA_DIR}/${P12}"
	set -e
	if [ ! -w $(dirname "${HOST_P12}") ]; then
		_err "The file ${HOST_P12} is not writable, please change the permissions"
		return 1
	fi
	_toPkcs "${HOST_P12}" "$_ckey" "$_ccert" "$_cca" "$PASS" unifi root
	if [ "$?" != "0" ]; then
		_err "Error generating pkcs12.  Please run again with --deubg and report a bug"
		return 1
	fi

	docker exec -it ${UNIFI_CONTAINER} /usr/bin/cp ${CNT_DATA_DIR}/keystore ${CNT_DATA_DIR}/keystore.bak
	
	docker exec -it ${UNIFI_CONTAINER} ${KEYTOOL} -delete -alias unifi -keystore ${CNT_DATA_DIR}/keystore -deststorepass ${PASS} || true
	
	docker exec -it ${UNIFI_CONTAINER} ${KEYTOOL} -importkeystore -deststorepass ${PASS} -destkeypass ${PASS} \
		   -destkeystore ${CNT_DATA_DIR}/keystore -srckeystore ${CNT_DATA_DIR}/${P12} \
		   -srcstoretype PKCS12 -srcstorepass ${PASS} -alias unifi -noprompt

	rm "${HOST_P12}"

	cd "${UNIFI_DOCKER_DIR}" && docker compose restart "${UNIFI_CONTAINER}"

	_savedeployconf UNIFI_DOCKER_DIR "${UNIFI_DOCKER_DIR}"
	_savedeployconf UNIFI_HOST_DATA_DIR "${UNIFI_HOST_DATA_DIR}"
	_savedeployconf UNIFI_CONTAINER "${UNIFI_CONTAINER}"
}
