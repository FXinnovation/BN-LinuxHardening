#!/usr/bin/env bash

SHORT_HOSTNAME_DOMAIN="eastus.cloudapp.azure.com"

SCRIPTDIR="$(cd "$(dirname "${0}")"; pwd)"
cd "${SCRIPTDIR}"
BASEDIR="${SCRIPTDIR}/../.."
LOCALCONFIGDIR="${BASEDIR}/local/config"
LOCALCONFIG="${LOCALCONFIGDIR}/remote-install-ansible.cfg"

echo "Localconfig: ${LOCALCONFIG}"

if [[ -e "${LOCALCONFIG}" ]]; then
    echo "Loagind local config..."
    localconfig=$(cat ${LOCALCONFIG})
    eval "${localconfig}"
fi

usage() {
    echo "Usage: ${0} <remote_hostname>"
    echo
    echo "  <remote_hostname>: short or fqdn hostname, if using the short form"
    echo "                     ${SHORT_HOSTNAME_DOMAIN} will be appended"
    exit 10
}

remote=${1}

if [[ "${remote}" == "" ]]; then
    usage
fi

hostname="${remote%%.*}"
domain="${remote#*.}"

if [[ "${hostname}" == "${domain}" ]]; then
    # this is a shortname, need to add the domain
    domain=${SHORT_HOSTNAME_DOMAIN}
fi

fqdn=${hostname}.${domain}

echo "Executing install-ansible.sh on ${fqdn}"

scp install-ansible.sh ${fqdn}:
ssh -t ${fqdn} "sudo ./install-ansible.sh"