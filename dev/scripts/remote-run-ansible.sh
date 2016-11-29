#!/usr/bin/env bash

SCRIPTDIR="$(cd "$(dirname "${0}")"; pwd)"
BASEDIR="${SCRIPTDIR}/../.."
LOCALDIR="${BASEDIR}/local"

cd "${SCRIPTDIR}"

hostinfo="${1}"

./remote-install-ansible.sh ${hostinfo}

#scp "${SCRIPTDIR}/../ansible/hardening-RH-7.2.yml" ${hostinfo}:
ssh -t ${hostinfo} rm -rf ansible/
scp -r "${SCRIPTDIR}/../ansible" ${hostinfo}:
ssh -t ${hostinfo} "cd ansible; sudo ansible-playbook hardening-RH-7.2.yml"

