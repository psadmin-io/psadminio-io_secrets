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
    password=$(bw list items --search "$name" --folderid $folder | jq -r .[].login.password)
    vaultResult=$?

    if [[ "${password}" == "null" ]]; then
        echo "WARNING - Unable to retrive password from vault!"
        return 1
    else
        eval "$varPass"'="${password}"'
        return 0
    fi
}

# Use this function to get a username from an env folder
function vault::getEnvUsername() #env, name, out typeUsername
{
    local env="$1"
    local name="$2"
    local varUser=$3
    local username=""
    local vaultResult=0

    if [[ -z $env || -z "$name" ]]; then
      echo "ERROR - The Env and Username Variable string are required"
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

    # Get env username
    username=$(bw list items --search 'sec_admin' --folderid $folder  | jq -r .[].login.username)
    vaultResult=$?

    if [[ "${username}" == "null" ]]; then
        echo "WARNING - Unable to retrive username from vault!"
        return 1
    else
        eval "$varUser"'="${username}"'
        return 0
    fi
}

