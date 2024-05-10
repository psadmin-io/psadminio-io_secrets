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
   echo "     Change a PeopleSoft UserId's password to match vault"
   echo "     -e <env>  : (Required) Env"
   echo "     -u <userId>: (Required) UserId to change password"
   echo "     -h               : Display this help"
   echo
   echo " This will pull the password from vault,using <env> as folder and <userId> as item name."
   echo " FYI: The '<env>:sec_admin' item from vault is used to access Peoplesoft to change passwords."
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

# Lookup security admin user and pass
vault::getEnvUsername $env 'sec_admin' changeUserName
vault::getEnvSecret $env 'sec_admin' changeUserPass

# Lookup new password
vault::getEnvSecret $env "$userId" vaultPassword
if [ -z "$vaultPassword" ]; then
    echo "Error finding password in vault"
    exit 1
fi

echo "INFO - Starting password change process for ${env}'s $userId"

# Setup DMS script
configFile="$PS_SCRIPT_BASE/.dmxcfg${currentDate}.txti"
scriptFile="$PS_SCRIPT_BASE/.accessid${currentDate}.dms"
echo "update PSOPRDEFN set PTOPERPSWDV2 = '$vaultPassword', OPERPSWDSALT = ' ', OPERPSWD = ' ', ENCRYPTED = 0 where OPRID = '$userId';" > $scriptFile
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
