#!/usr/bin/env bash

# Set Variables
export puppet_dir=/u01/app/psoft/dpk/puppet

# Override facts as needed
#export FACTER_io_secrets_group=none
#export FACTER_io_secrets_prefix=none
#export FACTER_io_secrets_group=none

# Apply vault test
puppet apply $puppet_dir/production/modules/io_secrets/examples/test.pp --confdir=$puppet_dir --debug

