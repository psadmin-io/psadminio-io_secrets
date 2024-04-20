# io_secrets::psvault
#
# TODO
#
# TODO 
# TODO
#
# @example
#   include io_secrets::psvault
class io_secrets::psvault (
  $ensure                 = $io_secrets::ensure,
  $ps_home_location       = hiera('ps_home_location'),
# TODO user of PS_HOME?
#  $psft_runtime_user_name    = $io_portalwar::psft_runtime_user_name,
#  $psft_runtime_group_name   = $io_portalwar::psft_runtime_group_name,
) {

  file {"Create ps_home custom patching notes":
    ensure  => file,
    path    => "${ps_home_location}/io_secrets.md",
    content => template('io_secrets/io_secrets.md.erb'),
  }

#    file { $index :
#      ensure  => file,
#      content => template('io_portalwar/index.html.erb'),
#      #owner   => $psft_runtime_user_name,
#      #group   => $psft_runtime_group_name,
#      #mode    => '0644',
#    }
#  }
  notify { "io_secrets::psvault": }

#  $custom_prefix          = hiera('custom_prefix', 'custom')
#  $jdk_location           = hiera('jdk_location')
#  $prebuilt_psvault       = hiera('prebuilt_psvault')
#  $ps_home_location       = hiera('ps_home_location')
#  $ps_app_home_location   = hiera('ps_app_home_location')
#  $ps_cust_home_location  = hiera('ps_cust_home_location')
#  $ps_vendor_location     = hiera('ps_vendor_location')
#  $ps_tools_home_location = hiera('ps_tools_home_location')
#  $appserver_domain_name  = hiera('appserver_domain_name')
#  $cobol_psrun_links      = hiera('cobol_psrun_links')

  # Create ps_home custom patching notes
#  $notes = @(EOT)
#    This PS_HOME was patched with custom updates.
#      - Updated psvault 
#    | EOT


#  # Deploy a custom psvault into the deployed ps_home_location  
#  if ($prebuilt_psvault) {
#    notice("Deploying prebuilt psvault from $prebuilt_psvault")
#
#    # PS_HOME/secvault
#    $pshome_secvault  = "${ps_home_location}/secvault/psvault"
#    notice("Deploying prebuilt psvault to $pshome_secvault")
#    file {"Deploy psvault to PS_HOME/secvault":
#      ensure => present,
#      path   => "${pshome_secvault}",
#      source => "${prebuilt_psvault}/piaconfig/properties/psvault",
#    }

#    # PS_HOME/setup/PsMpPIAInstall/archives
#    $pshome_setup_pia  = "${ps_home_location}/setup/PsMpPIAInstall/archives/psvault"
#    notice("Deploying prebuilt psvault to $pshome_setup_pia")
#    file {"Deploy psvault to PS_HOME/setup/pia":
#      ensure => present,
#      path   => "${pshome_setup_pia}",
#      source => "${prebuilt_psvault}/piaconfig/properties/psvault",
#    }

#    # PS_HOME/setup/PsMpPIAInstall/archives/WLPeopleSoft.jar
#    $pshome_setup_pia_jar  = "${ps_home_location}/setup/PsMpPIAInstall/archives/WLPeopleSoft.jar"
#    notice("Deploying prebuilt psvault to $pshome_setup_pia_jar")
#    notice("Using jar binary from jdk: $jdk_location")
#    exec { "Deploy psvault to PS_HOME/setup/pia/jar":
#      # set current wrk dir to base psvault location, then pack in jar
#      # packing from base location will give directory structure needed in jar
#      cwd      => "${prebuilt_psvault}",
#      command  => "${jdk_location}/bin/jar uf ${pshome_setup_pia_jar} piaconfig/properties/psvault",
#      path     => [ '/usr/bin', '/bin', '/usr/sbin' ],
#      #require => TODO - require jdk install?      
#    }
#  } #End Deploy a custom psvault 
}

