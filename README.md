# BN-LinuxHardening
Banque Nationale Linux Hardening

## Description

This roles provides numerous security-related configurations, providing all-round base protection.

It configures:

 * Configures package management e.g. allows only signed packages
 * Remove packages with known issues
 * Configures `pam` and `pam_limits` module
 * Shadow password suite configuration
 * Configures system path permissions
 * Disable core dumps via soft limits
 * Restrict Root Logins to System Console
 * Set SUIDs
 * Configures kernel parameters via sysctl

## Requirements

* Ansible

## how to use this role

inside your ansible installation copy this project under the **$ANSIBLE_ROOT/roles** folder.

After you can apply this role by specifying 
```
- hosts: webservers
  roles:
     - BN-LinuxHardening
```
please see [playbook_roles](http://docs.ansible.com/ansible/playbooks_roles.html) for more details

## Local Testing


Testing will require the use of vagrant and Virtualbox or VMWare to run tests locally. You will have to install Virtualbox and Vagrant on your system. See [Vagrant Downloads](http://downloads.vagrantup.com/) for a vagrant package suitable for your system. For all our tests we use `test-kitchen`. If you are not familiar with `test-kitchen` please have a look at [their guide](http://kitchen.ci/docs/getting-started).

Next install test-kitchen:

```bash
# Install dependencies
gem install bundler
bundle install
```

### Testing with Vagrant
```
# test on all machines
bundle exec kitchen test
```

For more information see [test-kitchen](http://kitchen.ci/docs/getting-started)
