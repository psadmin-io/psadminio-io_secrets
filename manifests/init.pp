class io_secrets (
  $ensure                     = $::io_secrets::params::ensure,
  $psvault                    = $::io_secrets::params::psvault,
) inherits ::io_secrets::params {
  if ($psvault) {
    contain ::io_secrets::psvault
  }
}

