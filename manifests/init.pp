class io_secrets (
  $ensure                    = $::io_portalwar::params::ensure,
#  $pia_domain_list           = $::io_portalwar::params::pia_domain_list,
#  $psft_runtime_user_name    = $::io_portalwar::params::psft_runtime_user_name,
#  $psft_runtime_group_name   = $::io_portalwar::params::psft_runtime_group_name,
#  $platform                  = $::io_portalwar::params::platform,
# $psvault = TODO
) inherits ::io_secrets::params {

#  validate_hash($pia_domain_list) TODO what is this? needed?

#  if ($psvault) {
#    contain ::io_secrets::psvault
#  }

}

