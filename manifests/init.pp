class io_secrets (
  $ensure                    = lookup('ensure', undef, first, 'present'),
  $ps_home_location          = lookup('ps_home_location', undef, undef, undef),
  $prebuilt_psvault          = lookup('prebuilt_psvault', undef, undef, '/u01/app/psoft/cust/secvault'),
  $jdk_location              = lookup('jdk_location', undef, undef, '/u01/app/psoft/pt/jdk'),
  $psft_install_user_name    = lookup('psft_install_user_name', undef, undef, 'psadm1'),
  $oracle_install_group_name = lookup('oracle_install_group_name', undef, undef, 'oinstall'),
) {
  if ($prebuilt_psvault) {
    contain ::io_secrets::psvault
  }
}

