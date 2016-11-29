#!/usr/bin/env bash

if /usr/bin/which ansible > /dev/null; then
    echo "Nothing to do, ansible is already installed"
    $(/usr/bin/which ansible) --version
else
    yum -y install epel-release
    yum -y install ansible
    yum -y erase epel-release


    echo '' >> /etc/ansible/hosts
    echo '# Configure ansible to run playbooks locally' >> /etc/ansible/hosts
    echo '' >> /etc/ansible/hosts
    echo 'localhost ansible_connection=local' >> /etc/ansible/hosts
    echo '' >> /etc/ansible/hosts
fi
