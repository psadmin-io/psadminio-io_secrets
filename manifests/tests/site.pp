node default {
    $env = hiera('env')                      # not in vault but in normal yaml data
    $db_user = hiera('io_secrets::db_user')  # secret in vault

    notify {"IO Secrets: $env db_user secret is $db_user":}
}
