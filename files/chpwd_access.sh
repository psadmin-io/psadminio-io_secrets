#!/bin/env bash
#
################################################################################
##
## File Name   : chpwd_access
## Description : Change the DB PS Access Id's password.  Update Vault, and update
##             :    the PSACCESSPROFILE table via dms
## Author      : Kyle Benson
##                 Forked and heavily modified from Nate Werner 
##                 https://github.com/UMN-PeopleSoft/psoft_passwd_mangment
## Created     : 04/30/2024
################################################################################
## Syntax      : chpwd_access -e <env> -u <AccessId>
##
## Parameters  : -e <env>  : Target env for password change
##             :
## Example     : chpwd_accessd -e IODEV -u SYSADM
##
################################################################################

# load bootstrap dynamic path
currentPath="$( cd "$(dirname "$0")" && pwd )"
#source ${currentPath%${currentPath#*scripts*/}}library/bootstrap.sh

# load needed libraries
#source $LIB_HOME/inventory.sh
#source $LIB_HOME/utilities.sh
#source $LIB_HOME/security.sh

# TODO
PS_SCRIPT_BASE=/tmp

env=""
accessid=""

## common functions
function usageInfo()
{
   echo "Usage:"
   echo "  chpwd_access -e <env>"
   echo "     Change a DB AccessID's password.  Update vault and update"
   echo "     the PSACCESSPROFILE table via dms"
   echo "     To script, pass the acccess password in env variable PS_ACCESS_PWD"
   echo "     -e <env>  : (Required) Env"
   echo "     -h               : Display this help"
   echo
   echo "Sample: chpwd_access -e IODEV"
   echo
   exit

}

######## Main program

# get user's paramters
while getopts ":ha:e:" optname; do
    case "$optname" in
      "e")
        env=$OPTARG
        ;;
      "h")
        usageInfo
        ;;
      "?")
        echo "Unknown option $OPTARG"
        usageInfo
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        usageInfo
        ;;
      *)
      # Should not occur
        echo "Unknown error while processing options"
        ;;
    esac
done

# verifiy required fields
if [[ -z "$env" ]]; then
  echo "Environment is required."
  usageInfo
fi

# setup log file for process
currentDate="$(date +%y%m%d_%H%M )"
passLogFile="$PS_SCRIPT_BASE/chpwd_access_${env}_$currentDate.log"
#TODO util::setLogFile "$passLogFile"

# Setup Vault access
#TODO sec::getandStoreVaultAccess
if [[ $? -ne 0 ]]; then
  util::log "ERROR" "Unable to setup vault access"
  exit 1
fi

# check if passed in with env variable
if [ -z "$PS_ACCESS_PWD" ]; then
  echo -n "Enter new $app$env DB Password:"
  read -s newDBPass
  echo
  echo -n "Re-Enter new $app$env DB Password:"
  read -s newDBPass2
  echo

  if [[ "$newDBPass" != "$newDBPass2" ]]; then
    echo "Password does not match!"
    exit 1
  fi
else
  # Use password stored in env var
  newDBPass="$PS_ACCESS_PWD"
fi

# only the $# seem to be safe with all various login scenarios
#if [[ $newDBPass =~ ['!@%^&*()_+|{};:/?.'] ]]; then
#  echo "An invalid character that can cause login problems was used ('!@%^&*()_+|{};:/?.').  Retry without these characters."
#  exit 1
#fi

#util::log "INFO" "Starting password change process for $app$env"

# apply password change to each app
  # Setup DMS script
  configFile="/psoft/admin/tmp/.dmxcfg${currentDate}.txt"
  scriptFile="/psoft/admin/tmp/.accessid${currentDate}.dms"
  echo "CHANGE_ACCESS_PASSWORD SYSADM1 ${newDBPass};" > $scriptFile

  # Get current Access pwd from vault
  sec::getAppEnvDBSecurity "$eachApp" "$env" appPasswd

  #Write config
  cat <<EOT > $configFile
-CT ORACLE
-CD ${eachApp^^}${env^^}
-CO SYSADM
-CP "$appPasswd"
-FP $scriptFile
EOT

  # Now run script 
  #TODO PS_SERVER_CFG=\$PS_CFG_HOME/appserv/prcs/$eachApp$env/psprcs.cfg psdmtx $configFile 2>&1
  dmsExitCode=$?
  # DMX will auto delete the config file, but script needs to be cleared
  rm $scriptFile
  #echo "DMS Exit Code: $dmsExitCode, Result: $dmsResult"
  
  # Check for errors
  if [[ "$dmsResult" == *"Successful completion"* ]]; then
     util::log "INFO" "DMS Change Access Password (And DB User) Successful."
  else
     util::log "ERROR" "Failed to run DMS Change Access Password, aborting, Results:  $dmsResult"
     exit 1
  fi

  echo "Make sure to update vault with new password"

done
