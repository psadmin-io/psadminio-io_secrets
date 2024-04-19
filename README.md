# psadminio-io_secrets
Hiera backend for PeopleSoft secrets stored in vaults to be use with DPK

# Info
Secret lookup is controlled by group, prefix, and/or suffix. These settings are pulled from `facts` that are configured in `hiera.yaml`.

```
:io_secrets:
  :vault:        'bw'
  :group_fact:   'io_secrets_group'
#  :prefix_fact:  'io_secrets_prefix'
#  :suffix_fact:  'io_secrets_suffix'
```

Facts can be setup in Facter config or at runtime via Environment Variables.
```
export FACTER_io_secrets_group='IODEV'
export FACTER_io_secrets_prefix='IODEV - '
export FACTER_io_secrets_suffix=' - IODEV'

puppet apply ...
```
