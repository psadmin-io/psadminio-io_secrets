class io_secrets (
  $ensure                 = 'present', #lookup('ensure', undef, first, 'present'),
  $ps_home_location       = '/u01/app/psoft/pt/ps_home8.61.02', #lookup('ps_home_location', undef, undef, undef),
  $prebuilt_psvault       = '/u01/app/psoft/cust/secvault', # lookup('prebuilt_psvault', undef, undef, '/u01/app/psoft/cust/secvault'),
  $jdk_location           = '/u01/app/psoft/pt/jdk', # lookup('jdk_location', undef, undef, '/u01/app/psoft/pt/jdk'),
) {
  if ($prebuilt_psvault) {
    contain ::io_secrets::psvault
  }
}

