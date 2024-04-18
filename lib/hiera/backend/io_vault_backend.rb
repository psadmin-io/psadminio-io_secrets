class Hiera
    module Backend
      class Io_secrets_backend
  
        def initialize
          Hiera.debug("Hiera IO Secrets backend starting")
          
          require 'json'

          @config = Config[:io_vault]
          @config[:vault] ||= ['none'] # bw, oci, test
          @config[:id] ||= ['none'] # ocid, etc
          @config[:group] ||= ['none'] # folder or other grouping, normally at Env level

          case @config[:vault]
          when 'test'
            @lookup_backend = "lookup_test"
          when 'bw'
            validate_bw()
            @lookup_backend = "lookup_bw"
          when 'oci'
            @lookup_backend = "lookup_oci"
          else
            @lookup_backend = "lookup_none"
          end

          if false
            raise Exception, "[hiera-io_secrets] some exception TODO '#{@config[:backend]}'"
          end
        end
  
        def lookup(key, scope, order_override, resolution_type)
          return if key.start_with?('io_vault::') == false
          return self.method(@lookup_backend).call(key, scope)
        end
        
        def lookup_none(key,scope)
          Hiera.debug("Hiera IO Secrets - skipping, no backend configured")
          return
        end
        
        def lookup_test(key,scope)
          Hiera.debug("Hiera IO Secrets - test vault, always returns test")
          return 'test'
        end

        def validate_bw()
          unless system("which jq > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] jq was not found in PATH"
          end
          unless system("which bw > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] Bitwarden CLI (bw) was not found in PATH"
          end
          unless system("bw login --check > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] bw is not logged in"
          end
          unless system("bw unlock --check > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] bw is not unlock, verify BW_SESSION is exported"
          end
          unless system("bw sync > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] bw had an issue syncing"
          end
        end

        def lookup_bw(key, scope)
          answer = nil
          
          return if key.start_with?('io_secrets::') == false
  
          secret_name = key.dup
          secret_name.slice! "io_secrets::"
  
          Hiera.debug("Looking up #{key} in IO Secrets bw")
          group_toggle = ""
          unless @config[:group] == 'none'
            group_id = `bw list folders --search #{@config[:group]} | jq -r .[].id`
            Hiera.debug("Group ID: #{group_id}")
            group_toggle = "--folderid #{group_id}"
          end

          # TODO - replace jq with Ruby JSON parsing? Otherwise we have to do multiple calls, since piping was having an issue...
          #secret_value = `bw list items --search #{secret_name} #{group_toggle} | jq -r .[].login.password`
          Hiera.debug("Secret Name: #{secret_name}")
          secret_json = `bw list items --search #{secret_name} #{group_toggle}`
          secret_value = `echo '#{secret_json}' | jq -r .[].login.password`
          #Hiera.debug("Secret Value: #{secret_value}")
          return if secret_value.empty?# TODO?
  
          Hiera.debug("Found #{key} in group #{@config[:group]} in IO Secrets bw")
          answer = Backend.parse_answer(secret_value, scope, {})

          return answer
       end

       def lookup_oci(key, scope)
          answer = nil
          return if key.start_with?('io_secrets::') == false

          secret = key.dup
          secret.slice! "io_secrets::"

          Hiera.debug("Looking up #{key} in IO Secrets oci")

          oci_vault_ocid = Facter.value(:oci_vault_ocid)
          Hiera.debug("OCI Value OCID: #{oci_vault_ocid}")

          ocicli = `oci secrets secret-bundle get-secret-bundle-by-name \
                      --vault-id=#{oci_vault_ocid} \
                      --secret-name=#{secret} \
                      --auth instance_principal \
                      | jq -jr '.data."secret-bundle-content".content' \
                      2>/dev/null `
          ocicli = Base64.decode64(ocicli)
          return if ocicli.empty?

          Hiera.debug("Found #{key} in IO Secrest oci")
          answer = Backend.parse_answer(ocicli, scope, {})

          return answer
        end
      end
    end
  end
