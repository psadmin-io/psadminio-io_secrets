# Library: vault
# Script: vault.sh
###########################

#includes
#if [ -z "$BOOTSTRAP_LOADED" ]; then
#  currentPath="$( cd "$(dirname "$0")" && pwd )"
#  source ${currentPath%${currentPath#*scripts*/}}library/bootstrap.sh
#fi

# Use this function to get a password from an env folder
function vault::getEnvSecret() #env, name, out typePassword
{
   local env="$1"
   local name="$2"
   local varPass=$3
   local currentDate=""
   local password=""
   local vaultResult=0

   if [ -z "$name" ]; then
     #util::log "ERROR" "The Env and Secret Name Variable string is required"
     return 1
   fi

   # got a valid key, lookup password
   # run ansible to read password from vault

   # Check if Vault is unlocked
   # TODO
   #bw list items --search '#{secret_name}' --folderid #{group_id}
  
  # Get env folder
  folder=$(bw list folders --search $env | jq -r .[].id)
  # TODO validate

  # Get password
  password=$(bw list items --search 'sec_admin' --folderid $folder  | jq -r .[].login.password)
  vaultResult=$?
   
  if [[ "${password}" == "null" ]]; then
     #util::log "WARNING" "Unable to retrive password from vault!"
     echo "WARNING"
     return 1
   else
     eval "$varPass"'="${password}"'
     return 0
   fi
}

