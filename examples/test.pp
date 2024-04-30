node default {
    $env = hiera('env')                            # not in vault but in normal yaml data
    $access_pwd = hiera('io_secrets::access_pwd')  # secret in vault

    notify {"IO Secrets: $env access_pwd secret is $access_pwd":}
}
