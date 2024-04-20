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
  $prebuilt_psvault       = '/u01/app/psoft/cust/secvault/psvault', # hiera('prebuilt_psvault'),
  $jdk_location           = '/u01/app/psoft/pt/jdk', # TODO
) {

  notify { "io_secrets::psvault": }
  
  file {"Create ps_home custom patching notes":
    ensure  => file,
    path    => "${ps_home_location}/io_secrets.md",
    content => template('io_secrets/io_secrets.md.erb'),
    #owner   => $psft_runtime_user_name,
    #group   => $psft_runtime_group_name,
    #mode    => '0644',
  }

  # Deploy a custom psvault into the deployed ps_home_location  
  if (true) { # TODO
    notice("Deploying prebuilt psvault from $prebuilt_psvault")

    # PS_HOME/secvault
    $pshome_secvault  = "${ps_home_location}/secvault/psvault"
    notice("Deploying prebuilt psvault to $pshome_secvault")
    file {"Deploy psvault to PS_HOME/secvault":
      ensure => present,
      path   => "${pshome_secvault}",
      source => "${prebuilt_psvault}", # TODO /piaconfig/properties/psvault",
    }

    # PS_HOME/setup/PsMpPIAInstall/archives
    $pshome_setup_pia  = "${ps_home_location}/setup/PsMpPIAInstall/archives/psvault"
    notice("Deploying prebuilt psvault to $pshome_setup_pia")
    file {"Deploy psvault to PS_HOME/setup/pia":
      ensure => present,
      path   => "${pshome_setup_pia}",
      source => "${prebuilt_psvault}", #/piaconfig/properties/psvault",
    }

    # PS_HOME/setup/PsMpPIAInstall/archives/WLPeopleSoft.jar
    $pshome_setup_pia_jar  = "${ps_home_location}/setup/PsMpPIAInstall/archives/WLPeopleSoft.jar"
    notice("Deploying prebuilt psvault to $pshome_setup_pia_jar")
    notice("Using jar binary from jdk: $jdk_location")
    exec { "Deploy psvault to PS_HOME/setup/pia/jar":
      # set current wrk dir to base psvault location, then pack in jar
      # packing from base location will give directory structure needed in jar
      cwd      => "/u01/app/psoft/cust/secvault", #TODO ${prebuilt_psvault}",
      command  => "${jdk_location}/bin/jar uf ${pshome_setup_pia_jar} piaconfig/properties/psvault", # TODO
      path     => [ '/usr/bin', '/bin', '/usr/sbin' ],
      #require => TODO - require jdk install?      
    }
  } 
}

