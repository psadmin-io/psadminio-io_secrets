#!/bin/env bash
#
################################################################################
##
## File Name   : chpwd_user.sh
## Description : Change the PS User Id's password
## Author      : Kyle Benson
##                 Forked and heavily modified from Nate Werner
##                 https://github.com/UMN-PeopleSoft/psoft_passwd_mangment
## Created     : 04/30/2024
################################################################################
## Syntax      : chpwd_user.sh -e <env> -u <UserId>
##
## Parameters  : -e <env>  : Target env for password change
##             : -u <userid> : PeopleSoft user id to change password for
##             :
## Example     : chpwd_user.sh -e IODEV -u PSA
##
################################################################################

currentPath="$( cd "$(dirname "$0")" && pwd )"

# load needed libraries
LIB_HOME=/u01/app/psoft/dpk/puppet/production/modules/io_secrets/files
source $LIB_HOME/vault.sh

env=""
userId=""

## common functions
function usageInfo()
{
   echo "Usage:"
   echo "  chpwd_user.sh -e <env> -u <userId>"
   echo "     Change a PeopleSoft UserId's password and update vault"
   echo "     To script, pass the userid password in env variable PS_USER_PWD"
   echo "     -e <env>  : (Required) Env"
   echo "     -u <userId>: (Required) UserId to change password"
   echo "     -h               : Display this help"
   echo
   echo " This will prompt for the new password unless the new password is set in the "
   echo "   environment variable 'PS_USER_PWD'"
   #TODO echo " FYI: The user 'PS' is used to access Peoplesoft to change passwords, changing PS"
   #echo "   will change how other passwords are changed due to this use dependency!"
   #echo
   exit
}

######## Main program

# get user's paramters
while getopts ":ha:e:u:t:" optname; do
    case "$optname" in
      "e")
        env=$OPTARG
        ;;
      "u")
        userId=$OPTARG
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
if [[ -z "$env" || -z "$userId" ]]; then
  echo "Environment and User Id are required."
  usageInfo
fi

# setup log file for process
currentDate="$(date +%y%m%d_%H%M )"
PS_SCRIPT_BASE=/tmp
passLogFile="$PS_SCRIPT_BASE/changeUserPassword_${app}_${env}_${userId}_$currentDate.log"

# check if passed in with env variable
if [ -z "$PS_USER_PWD" ]; then
  echo -n "Enter new $app$env $userId Password:"
  read -s newUserPass
  echo
  echo -n "Re-Enter new $app$env $userId Password:"
  read -s newUserPass2
  echo

  if [[ "$newUserPass" != "$newUserPass2" ]]; then
    echo "Password does not match!"
    exit 1
  fi
else
  # Use password stored in env var
  newUserPass="$PS_USER_PWD"
fi

# Lookup security admin user and pass
changeUserName="VP1" # TODO
vault::getEnvSecret $env 'sec_admin' changeUserPass

echo "INFO - Starting password change process for ${env}'s $userId"

# Setup DMS script
configFile="$PS_SCRIPT_BASE/.dmxcfg${currentDate}.txt"
scriptFile="$PS_SCRIPT_BASE/.accessid${currentDate}.dms"
echo "update PSOPRDEFN set PTOPERPSWDV2 = '$newUserPass', OPERPSWDSALT = ' ', OPERPSWD = ' ', ENCRYPTED = 0 where OPRID = '$userId';" > $scriptFile
echo "ENCRYPT_PASSWORD $userId;" >> $scriptFile

# Setup DMS config
cat <<EOT > $configFile
-CT ORACLE
-CD "${PS_DBNAME?}"
-CO "$changeUserName"
-CP "$changeUserPass"
-FP $scriptFile
EOT

# Run DMS
dmsResult=$(PS_SERVER_CFG=$PS_CFG_HOME/appserv/prcs/PRCSDOM/psprcs.cfg psdmtx $configFile)
dmsExitCode=$?
# DMX will auto delete the config file, but script needs to be cleared
rm $scriptFile
if [ -e $configFile ]; then
   rm $configFile
fi

# Check for errors
if [[ "$dmsResult" == *"Successful completion"* ]]; then
   echo "INFO - DMS Change User Password Successful for $userId in $env"
else
   echo "ERROR - Failed to run DMS Change User Password, aborting, Results:  $dmsResult"
   exit 1
fi
