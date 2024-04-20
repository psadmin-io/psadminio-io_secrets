# io_secrets::psvault
#
# TODO
#
# TODO 
# TODO
#
# @example
#   include io_secrets::psvault
class io_portalwar::psvault (
  $ensure                    = $io_portalwar::ensure,
#  $pia_domain_list           = $io_portalwar::pia_domain_list,
#  $redirect_target           = $io_portalwar::redirect_target,
#  $psft_runtime_user_name    = $io_portalwar::psft_runtime_user_name,
#  $psft_runtime_group_name   = $io_portalwar::psft_runtime_group_name,
) {

#  $pia_domain_list.each |$domain_name, $pia_domain_info| {
#    # notify {"Config settings for ${domain_name}: ${pia_domain_info}":}
#    $ps_cfg_home_dir = $pia_domain_info['ps_cfg_home_dir']
#
#    $index = "${ps_cfg_home_dir}/webserv/${domain_name}/applications/peoplesoft/PORTAL.war/index.html"
#

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
  $notes = @(EOT)
    This PS_HOME was patched with custom updates.
      - Updated psvault 
    | EOT

  file {"Create ps_home custom patching notes":
    ensure  => present,
    path    => "${ps_home_location}/${custom_prefix}_ps_home_patching.md",
    content => $notes,
  }

  # Deploy a custom psvault into the deployed ps_home_location  
  if ($prebuilt_psvault) {
    notice("Deploying prebuilt psvault from $prebuilt_psvault")

    # PS_HOME/secvault
    $pshome_secvault  = "${ps_home_location}/secvault/psvault"
    notice("Deploying prebuilt psvault to $pshome_secvault")
    file {"Deploy psvault to PS_HOME/secvault":
      ensure => present,
      path   => "${pshome_secvault}",
      source => "${prebuilt_psvault}/piaconfig/properties/psvault",
    }

    # PS_HOME/setup/PsMpPIAInstall/archives
    $pshome_setup_pia  = "${ps_home_location}/setup/PsMpPIAInstall/archives/psvault"
    notice("Deploying prebuilt psvault to $pshome_setup_pia")
    file {"Deploy psvault to PS_HOME/setup/pia":
      ensure => present,
      path   => "${pshome_setup_pia}",
      source => "${prebuilt_psvault}/piaconfig/properties/psvault",
    }

    # PS_HOME/setup/PsMpPIAInstall/archives/WLPeopleSoft.jar
    $pshome_setup_pia_jar  = "${ps_home_location}/setup/PsMpPIAInstall/archives/WLPeopleSoft.jar"
    notice("Deploying prebuilt psvault to $pshome_setup_pia_jar")
    notice("Using jar binary from jdk: $jdk_location")
    exec { "Deploy psvault to PS_HOME/setup/pia/jar":
      # set current wrk dir to base psvault location, then pack in jar
      # packing from base location will give directory structure needed in jar
      cwd      => "${prebuilt_psvault}",
      command  => "${jdk_location}/bin/jar uf ${pshome_setup_pia_jar} piaconfig/properties/psvault",
      path     => [ '/usr/bin', '/bin', '/usr/sbin' ],
      #require => TODO - require jdk install?      
    }
  } #End Deploy a custom psvault 
}

