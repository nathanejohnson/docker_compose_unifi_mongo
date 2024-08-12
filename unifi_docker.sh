#!/usr/bin/bash

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


	_getdeployconf UNIFI_CONTAINER
	if [ -z "${UNIFI_CONTAINER}" ]; then
		UNIFI_CONTAINER=unifi-network-application
	fi

	if ! docker ps | grep ${UNIFI_CONTAINER} > /dev/null; then
		_err "docker container not running"
		return 1
	fi
	_dinsp=$(docker inspect "${UNIFI_CONTAINER}")
	if [ "$?" != "0" ]; then
	   _err "docker inspect failed"
	   return 1
	fi

	_debug2 DINSP "${_dinsp}"

	_debug UNIFI_CONTAINER "${UNIFI_CONTAINER}"

	_getdeployconf UNIFI_DOCKER_DIR
	_default_dcumd="${HOME}/docker_compose_unifi_mongo"

	_getdeployconf UNIFI_HOST_DATA_DIR

	if [ -z "$UNIFI_DOCKER_DIR" ]; then
		_dcyml=$(echo "${_dinsp}"  | grep com.docker.compose.project.config_files | sed -E 's/^[^:]*: "([^"]*)",?$/\1/')
		_debug dcyml "${_dcyml}"
		if [ ! -z "${_dcyml}" ] && [ -f "${_dcyml}" ]; then
			_debug "using ${_dcyml} location from ${UNIFI_CONTAINER} container inspection as basis of UNIFI_DOCKER_DIR"
			UNIFI_DOCKER_DIR=$(dirname $_dcyml)
		elif [ -d "${_default_dcumd}" ]; then
			_debug "using ${_default_dcumd} as default UNIFI_DOCKER_DIR"
			UNIFI_DOCKER_DIR="${_default_dcumd}"
		elif [ -z "${UNIFI_HOST_DATA_DIR}" ]; then
			_err "must set UNIFI_DOCKER_DIR or UNIFI_HOST_DATA_DIR environment variable"
			return 1
		fi
	fi
	_debug UNIFI_DOCKER_DIR "${UNIFI_DOCKER_DIR}"


	if [ -z "${UNIFI_HOST_DATA_DIR}" ]; then
		UNIFI_HOST_DATA_DIR="${UNIFI_DOCKER_DIR}/unifi-data/data"
	fi
	_debug UNIFI_HOST_DATA_DIR "$UNIFI_HOST_DATA_DIR"


	# this password is the default keystore passphrase for unifi network application, probably keep that the same.
	PASS=aircontrolenterprise


	KEYSTORE=${UNIFI_HOST_DATA_DIR}/keystore
	if [ ! -w "${KEYSTORE}" ]; then
		_err "The file ${KEYSTORE} is not writable, please change the permissions"
		return 1
	fi
	cp "${KEYSTORE}" "${KEYSTORE}.bak"
	_toPkcs "${KEYSTORE}" "$_ckey" "$_ccert" "$_cca" "$PASS" unifi root
	if [ "$?" != "0" ]; then
		mv "${KEYSTORE}.bak" "${KEYSTORE}"
		_err "Error generating pkcs12.  Please run again with --debug and report a bug"
		return 1
	fi

	_debug "restarting ${UNIFI_CONTAINER}"
	docker restart "${UNIFI_CONTAINER}"

	_savedeployconf UNIFI_DOCKER_DIR "${UNIFI_DOCKER_DIR}"
	_savedeployconf UNIFI_HOST_DATA_DIR "${UNIFI_HOST_DATA_DIR}"
	_savedeployconf UNIFI_CONTAINER "${UNIFI_CONTAINER}"
	return 0
}
