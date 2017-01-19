# BN-LinuxHardening
Banque Nationale Linux Hardening

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
