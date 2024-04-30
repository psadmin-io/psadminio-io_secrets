# Library: vault
# Script: vault.sh
###########################

# Use this function to get a password from an env folder
function vault::getEnvSecret() #env, name, out typePassword
{  
    local env="$1"
    local name="$2"
    local varPass=$3
    local password=""
    local vaultResult=0

    if [[ -z $env || -z "$name" ]]; then
      echo "ERROR - The Env and Secret Name Variable string is required"
      return 1
    fi

    # Sync vault
    bw sync > /dev/null  
  
    # Get env folder
    folder=$(bw list folders --search $env | jq -r .[].id)
    if [[ "${folder}" == "null" ]]; then
        echo "WARNING - Unable to retrive $env folder from vault!"
        return 1
    fi

    # Get env password
    password=$(bw list items --search 'sec_admin' --folderid $folder  | jq -r .[].login.password)
    vaultResult=$?
   
    if [[ "${password}" == "null" ]]; then
        echo "WARNING - Unable to retrive password from vault!"
        return 1
    else
        eval "$varPass"'="${password}"'
        return 0
    fi
}

