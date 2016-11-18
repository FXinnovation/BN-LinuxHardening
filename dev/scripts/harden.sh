#!/usr/bin/env bash

SCRIPTDIR="$(cd "$(dirname "${0}")"; pwd)"
cd "${SCRIPTDIR}"

DATADIR=/usr/share/hardening
mkdir -p "${DATADIR}"
DATAFILE="${DATADIR}/hardening.dat"
touch "${DATAFILE}"

#source "${DATAFILE}"
eval $(cat ${DATAFILE})

# This function executes a step (command) if it is not marked as completed
# and marks it a completed if it succeeds. If the command fails it will stop
# script execution with the error message provided and the exit code of the
# failed command
# $1: Step Name
# $2: Command to execute
executeStep() {
  originalStepName="${1}"
  stepName="Hardening_${1}"
  commandToExecute="${2}"
  shift
  echo "Step: ${originalStepName}"
  if [[ "${!stepName}" == "completed" ]]; then
    echo "  Ignored, already completed"
    return
  fi
  eval ${commandToExecute}
  rc=$?
  if [[ "${rc}" != "0" ]]; then
    echo "  ERROR: Step '${originalStepName}' failed with error code ${rc}"
    echo "  The command is: "
    echo "  --- Command Start ---"
    echo "  ${commandToExecute}"
    echo "  --- Command End ---"
    exit ${rc}
  else
    # mark as completed
    echo "${stepName}=completed" >> "${DATAFILE}"
    echo "  OK"
  fi
}


disableService() {
  serviceName="${1}"
  if [[ -e "/etc/init.d/${serviceName}" ]]; then
    executeStep "DisableService${serviceName/-/_}" "chkconfig ${serviceName} off"
  else
    echo "WARNING: Service ${serviceName} is not present, unable to disable."
  fi
}

# Hardening script for Centos 6.8
# will probably work on RHEL 6.8, needs to be tested

executeStep "YumUpdate" "yum update -y"

#disks=$(lsblk -P | grep 'TYPE="disk"')
#disk_names=()

#while read -r disk; do
#    eval "${disk//:/_}"
#    echo "Name: ${NAME}"
#    if !(lsblk -P /dev/${NAME} | grep 'TYPE="part"' > /dev/null)  then
#        echo "  Disk has no partitions"
#        disk_names+=(${NAME})
#    fi
#done <<< "${disks}"

#echo "Disks with no partitions: [${disk_names[@]}]"

# /tmp
executeStep "PartedLabelTmp" "parted -s /dev/sdc mklabel msdos"
executeStep "PartedPartTmp" "parted -s /dev/sdc mkpart primary 1M 100%"
executeStep "MkfsTmp" "mkfs.ext4 -F /dev/sdc1"
executeStep "FstabTmp" "echo -e '/dev/sdc1\t\t/tmp\t\t\text4\tdefaults,nodev,nosuid,noexec \t1 2' >>/etc/fstab"
executeStep "MountTmp" "mount /tmp"
executeStep "ChmodTmp" "chmod 1777 /tmp"
executeStep "BindMountVarTmp" "mount --bind /tmp /var/tmp"
executeStep "FstabVarTmp" "echo -e '/tmp\t\t\t/var/tmp\t\tnone\tbind \t\t\t\t0 0' >>/etc/fstab"

# /var/log
executeStep "PartedLabelVarLog" "parted -s /dev/sdd mklabel msdos"
executeStep "PartedPartVarLog" "parted -s /dev/sdd mkpart primary 1M 100%"
executeStep "MkfsVarLog" "mkfs.ext4 -F /dev/sdd1"
executeStep "FstabVarLog" "echo -e '/dev/sdd1\t\t/var/log\t\text4\tdefaults \t\t\t1 2' >>/etc/fstab"

# Set Sticky Bit on All World-Writable Directories, excluding /mnt/resource (an azure specific temp directory)
worldDirectoriesCount=$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | wc -l)
if [[ "${worldDirectories}" -ne 0 ]]; then
  executeStep "StickyWorldWritable" "df --local -P | grep -v '/mnt/resource' | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs chmod a+t '{}'"
else
  echo "No World Writable directories found, skipping step 'StickyWorldWritable'"
fi

# /boot/grub/grub.conf
executeStep "ChownGrubConf" "chown root:root /boot/grub/grub.conf"
executeStep "ChmodGrubConf" "chmod og-rwx /boot/grub/grub.conf"

# Core Dumps
executeStep "HardCore0" "echo 'hard core 0' >> /etc/security/limits.conf"
executeStep "FsSuidDumpable" "echo 'fs.suid_dumpable = 0' >> /etc/sysctl.conf"

# Exec shield
executeStep "ExecShield" "echo 'kernel.exec-shield = 1' >> /etc/sysctl.conf"

executeStep "RandomizeVaSpace" "echo 'kernel.randomize_va_space = 2' >> /etc/sysctl.conf"

# Remove Legacy services
executeStep "RemoveTelnetServer" "yum -y erase telnet-server"

#  Compilation Tools (need complete list)
executeStep "RemoveGcc" "yum -y erase gcc"
executeStep "RemoveCmake" "yum -y erase cmake"
# Unable to remove make, as this tries to remove yum
#executeStep "RemoveMake" "yum -y erase make"

executeStep "RemoveRshServer" "yum -y erase rsh-server"
executeStep "RemoveRsh" "yum -y erase rsh"
executeStep "RemoveYpbind" "yum -y erase ypbind"
executeStep "RemoveYpserv" "yum -y erase ypserv"
executeStep "RemoveTftp" "yum -y erase tftp"
executeStep "RemoveTftpServer" "yum -y erase tftp-server"
executeStep "RemoveTalk" "yum -y erase talk"
executeStep "RemoveTalkServer" "yum -y erase talk-server"
executeStep "RemoveXinetd" "yum -y erase xinetd"
disableService "chargen-dgram"
disableService "chargen-stream"
disableService "daytime-dgram"
disableService "daytime-stream"
disableService "echo-dgram"
disableService "echo-stream"
disableService "tcpmux-server"
disableService "avahi-daemon"
disableService "cups"
executeStep "RemoveTelnetServer" "yum -y erase dhcp"
disableService "nfslock"
disableService "rpcgssd"
disableService "rpcbind"
disableService "rpcidmapd"
disableService "rpcsvcgssd"

# Disable IP Forwarding
executeStep "DisableIPForwarding" "echo 'net.ipv4.ip_forward=0' >> /etc/sysctl.conf"

# Disable Send Packet Redirects
executeStep "DisableSendPacketRedirectsAll" "echo 'net.ipv4.conf.all.send_redirects=0' >> /etc/sysctl.conf"
executeStep "DisableSendPacketRedirectsDefault" "echo 'net.ipv4.conf.default.send_redirects=0' >> /etc/sysctl.conf"

# Disable ICMP Redirect Acceptance
executeStep "DisableICMPRedirectAcceptanceAll" "echo 'net.ipv4.conf.all.accept_redirects=0' >> /etc/sysctl.conf"
executeStep "DisableICMPRedirectAcceptanceDefault" "echo 'net.ipv4.conf.default.accept_redirects=0' >> /etc/sysctl.conf"

# Enable Bad Error Message Protection
executeStep "EnableBadErrorMessageProtection" "echo 'net.ipv4.icmp_ignore_bogus_error_responses parameter=1' >> /etc/sysctl.conf"

# Install and use the rsyslog to manage the logs
executeStep "InstallRsyslog" "yum -y install rsyslog"
disableService "syslog"
executeStep "EnableRsyslog" "chkconfig rsyslog on"

rsyslogSecureGroup=root

# Configure rsyslog.conf
cat > /tmp/rsyslog.conf.$$ <<EOD

\$FileOwner syslog
\$FileGroup ${rsyslogSecureGroup}
\$FileCreateMode 0640
\$DirCreateMode 0750
\$Umask 0027
\$PrivDropToUser syslog
\$PrivDropToGroup syslog


auth,authpriv,user.* /var/log/secure
kern.* /var/log/kern.log 
daemon.* /var/log/daemon.log 
syslog.* /var/log/syslog
lpr,news,uucp,local0,local1,local2,local3,local4,local5,local6.* /var/log/unused.log

# *.* @@remoteHost.siem"

EOD

executeStep "InstallNewRsyslogConf" "cp /tmp/rsyslog.conf.$$ /etc/rsyslog.conf"

rm -f /tmp/rsyslog.conf.$$

executeStep "ChangeVarLogOwner" "chown syslog:root /var/log"
for logFilename in "secure" "kern.log" "daemon.log" "syslog" "unused.log" "local2_samhain.log"; do
  if [[ -e "/var/log/${logFilename}" ]]; then
    executeStep "ChangeLogOwner_${logFilename/./_}" "chown syslog:root /var/log/${logFilename}"
    executeStep "ChangeLogPerms_${logFilename/./_}" "chmod g-wx,o-rwx /var/log/${logFilename}"
  fi
done




