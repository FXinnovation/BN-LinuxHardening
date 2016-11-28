#!/usr/bin/env bash

SCRIPTDIR="$(cd "$(dirname "${0}")"; pwd)"
BASEDIR="${SCRIPTDIR}/../.."
LOCALDIR="${BASEDIR}/local"
IMAGESDIR="/var/lib/libvirt/images"


cd "${SCRIPTDIR}"

vmName=BNHardening
memorySize=2048
vcpus=1
sourceDisk="${IMAGESDIR}/Centos-7.2.qcow2"
snapshotDisk="${IMAGESDIR}/${vmName}.qcow2"
vmXMLFilename="/tmp/${vmName}_$$.xml"
vmUser=fxautomata

echo "vmXMLFilename=${vmXMLFilename}"

cleanUp() {
    if [[ -e "${vmXMLFilename}" ]]; then
        rm -f "${vmXMLFilename}"
    fi
}

trap cleanUp SIGHUP SIGINT SIGTERM

if virsh list | grep "${vmName}" | grep -q running; then
    virsh destroy "${vmName}"
    sleep 1
fi

if virsh list --all | grep "${vmName}" | grep -q "shut off"; then
    virsh undefine "${vmName}"
fi

if [[ -e "${snapshotDisk}" ]]; then
    rm -f "${snapshotDisk}"
fi

qemu-img create -f qcow2 -b "${sourceDisk}" "${snapshotDisk}"

virt-install --name "${vmName}" \
  --memory "${memorySize}" \
  --vcpus "${vcpus}" \
  --import --disk "${snapshotDisk}" \
  --print-xml \
  --dry-run >${vmXMLFilename}

output=$(cat "${vmXMLFilename}" | grep '<mac')
trimmedOutput=$(echo ${output})
temp="${trimmedOutput#\<mac address=\"}"
macAddress="${temp%\"/\>}"

virsh create "${vmXMLFilename}"

echo -n "Waiting for ip address"
until virsh domifaddr "${vmName}" | grep -q 'ipv4'; do
    echo -n '.'
    sleep 1
done
echo

output=$(virsh domifaddr "${vmName}" | grep 'ipv4' | awk '{print $4}')
echo "output=${output}"
vmIP="${output%/*}"

${SCRIPTDIR}/remote-install-ansible.sh ${vmUser}@${vmIP}

echo "SCRIPT_vmIP=${vmIP}"
echo "SCRIPT_macAddress=${macAddress}"

cleanUp