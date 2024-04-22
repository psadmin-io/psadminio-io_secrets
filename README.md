# io_secrets

#### Table of Contents

- [io\_secrets](#io_secrets)
      - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Setup](#setup)
  - [Usage](#usage)
  - [Reference](#reference)
  - [Limitations](#limitations)
  - [Development](#development)

## Overview

This modules is meant to assisit in managing PeopleSoft secrets as a bolt-on to the Oracle delivered PeopleSoft
DPK.

To use this module you must be a PeopleSoft customer using the DPK installer
process based on puppet to deploy nodes. This module includes a custom Hiera Backend to securely pull secrets, 
as well as other feature. Configuration is done via `hiera.yaml` and Facter.

## Setup

### Setup Requirements

* PeopleSoft installed via DPK (Puppet)
* A supported vault to store secrets
    * Bitwarden
    * OCI Vault

### Module install
```
puppet_dir=/u01/app/psoft/dpk/puppet
cd $puppet_dir/production/modules
git clone https://github.com/psadmin-io/psadminio-io_secrets.git io_secrets
```

### Vault Setup
Review the [examples/hiera.yaml](examples/hiera.yaml) example and update yours as needed. 

Vault options are:

* `bw`   - Bitwarden
* `oci`  - OCI Vault
* `none` - No vault lookups
* `test` - All secret lookup return `pass`

Addition config can be done via Facter. These configuration facts can be set statically via config file or dynamically via environment variables.
The list of vaild configuration facts is found in [facts.d/io_secrets.yaml](facts.d/io_secrets.yaml). Best practice is to copy this file to `/etc/facter/facts.d` or `$HOME/.facter/facts.d` and adjust default values as needed.

To override default configuration facts, export environtment variables before running `puppet apply`.
```
export FACTER_io_secrets_group=FSDEV
puppet apply ...

# or
FACTER_io_secrets_group=FSDEV puppet apply ...
```

### Bitwarden Setup
To use Bitwarden or Vaultwarden as a vault backend, this module assumes you have `bw` installed, logged in and unlocked.
If this is not the case when `puppet apply` is run, it will throw an exception.

```
# install bw
cd ~/bin
wget "https://vault.bitwarden.com/download/?app=cli&platform=linux" -O bw.zip
unzip bw.zip
rm -f bw.zip

# login and unlock
export NODE_EXTRA_CA_CERTS=/var/lib/containers/vault/certs/cert.pem # needed if using self-signed certs
bw config server https://vault.psadmin.io:443
bw login
export BW_SESSION="..."
```

### OCI Setup
TODO

## Usage

### Vault Backend
Use variables in your DPK data that match this pattern `io_secrets::secret_name`. 
In this example, the backend will look in the vault for a secret with the name `secret_name`.

Secrets in vaults can be organized in different ways. This backend deals with organization via configuration facts.

* `io_secrets_group`
    * bw  - value is used to lookup a Folder name to search in.
    * oci - valee is used as the Compartment OCID to search in.
* `io_secrets_prefix`
    * all - value is added to the front of a secret name. 
        ```
        io_secrets_prefix="IODEV - "
        io_secrets::secret_name
        lookup = 'FSDEV - secret_name'
        ```
* `io_secrets_suffix`
    * all - value is added to the end of a secret name. 
        ```
        io_secrets_prefix=" - IODEV"
        io_secrets::secret_name
        lookup = 'secret_name - IODEV'
        ```

### Test
```
<MODULE_PATH>/examples/puppet_apply.sh
```

## Reference

## Limitations

## Development
