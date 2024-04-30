class Hiera
    module Backend
      class Io_secrets_backend
        def initialize
          require 'json'          
          
          Hiera.debug("Hiera IO Secrets backend starting")

          # Lookup config
          @config = Config[:io_secrets] || raise("[hiera-io_secrets] there was an issue finding :io_secrets config in hiera.yaml")
          @vault = @config[:vault]
          Hiera.debug("Hiera IO Secrets - vault = #{@vault}")

          # Lookup facts
          @id = Facter.value('io_secrets_id') || raise("[hiera-io_secrets] fact 'io_secrets_id' was not found")
          Hiera.debug("Hiera IO Secrets - id = #{@id}")
          @group = Facter.value('io_secrets_group') || raise("[hiera-io_secrets] fact 'io_secrets_group' was not found")
          Hiera.debug("Hiera IO Secrets - group = #{@group}")
          @prefix = Facter.value('io_secrets_prefix') || raise("[hiera-io_secrets] fact 'io_secrets_prefix' was not found")
          Hiera.debug("Hiera IO Secrets - prefix = #{@prefix}")
          @suffix = Facter.value('io_secrets_suffix') || raise("[hiera-io_secrets] fact 'io_secrets_suffix' was not found")
          Hiera.debug("Hiera IO Secrets - suffix = #{@suffix}")

          # Validate and set lookup for vault type
          case @config[:vault]
          when 'test'
            @lookup_backend = "lookup_test"
          when 'bw'
            validate_bw()
            @lookup_backend = "lookup_bw"
          when 'oci'
            validate_oci()
            @lookup_backend = "lookup_oci"
          else
            @lookup_backend = "lookup_none"
          end
        end
 
        def lookup(key, scope, order_override, resolution_type)
          return if key.start_with?('::io_secrets::') == false   # skip if not an `io_secrets` key
          return self.method(@lookup_backend).call(key, scope) # lookup method based on vualt type
        end
        
        def lookup_none(key,scope)
          Hiera.debug("Hiera IO Secrets - skipping, no backend configured")
          return
        end
        
        def lookup_test(key,scope)
          Hiera.debug("Hiera IO Secrets - test vault, always returns 'pass'")
          return 'pass'
        end

        def validate_bw()
          unless system("which bw > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] Bitwarden CLI (bw) was not found in PATH"
          end
          unless system("bw login --check > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] bw is not logged in"
          end
          unless system("bw unlock --check > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] bw is not unlocked, verify BW_SESSION is exported"
          end
          unless system("bw sync > /dev/null")
            raise Exception, "[hiera-io_secrets][bw] bw had an issue syncing"
          end
        end

        def lookup_bw(key, scope)
          answer = nil          
 
          # Group Lookup
          Hiera.debug("Looking up #{key} in IO Secrets bw")
          if @group == 'none'
            group_toggle = "" # skip group criteria if not set in config
	  else
            bw_json = JSON.parse(`bw list folders --search #{@group}`)
            if bw_json.size == 1
              group_id = bw_json[0]["id"]
              Hiera.debug("Group ID: #{group_id}")
              group_toggle = "--folderid #{group_id}"
            elsif bw_json.size > 1
              raise Exception, "[hiera-io_secrets] multiple groups were found, group name '#{@config[:group]}' not unique in vault"
            else
              raise Exception, "[hiera-io_secrets] no '#{@config[:group]}' group was found in vault"
            end
          end

          # Secret Name Prep
          secret_name = key.dup
          secret_name.slice! "::io_secrets::"
          secret_name = @prefix + secret_name unless @prefix == 'none'
          secret_name = secret_name + @suffix unless @suffix == 'none'

          # Secret Lookup
          Hiera.debug("Secret Name: #{secret_name}")
          bw_json = JSON.parse(`bw list items --search '#{secret_name}' #{group_toggle}`)
          
          if bw_json.size == 1
            secret_value = bw_json[0]["login"]["password"]
            #Hiera.debug("Secret Value: #{secret_value}")
          elsif bw_json.size > 1
            raise Exception, "[hiera-io_secrets] multiple secrets were found, secret name '#{secret_name}' not unique in vault"
          else
            return # no secret found
          end
  
          Hiera.debug("Found #{key} in IO Secrets bw")
          answer = Backend.parse_answer(secret_value, scope, {})

          return answer
       end

        def validate_oci()
          unless system("which oci > /dev/null")
            raise Exception, "[hiera-io_secrets][oci] OCI CLI (oci) was not found in PATH"
          end
          unless system("oci iam compartment list > /dev/null")
            raise Exception, "[hiera-io_secrets][oci] basic compartment query failed, oci config is likely incorrect"
          end
          #TODO if this returns no secrets, then fail validation
          # unless JSON.parse(system("oci vault secret list --compartment-id #{@group}")).size > 0
          #  raise Exception, "[hiera-io_secrets][oci] issue finding secrets in vaults in group(compartment)"
          #end
        end

       def lookup_oci(key, scope)
          answer = nil

          secret = key.dup
          secret.slice! "::io_secrets::"

          Hiera.debug("Looking up #{key} in IO Secrets oci")

          # TODO out in a rescure clause around all this?
      
          # Group Lookup
          Hiera.debug("Looking up #{key} in IO Secrets oci")
          #if @group.nil?
          #  group_toggle = "" # skip group criteria if not set in config
	  #else
          #  bw_json = JSON.parse(`bw list folders --search #{@group}`)
          #  if bw_json.size == 1
          #    group_id = bw_json[0]["id"]
          #    Hiera.debug("Group ID: #{group_id}")
          #    group_toggle = "--folderid #{group_id}"
          #  elsif bw_json.size > 1
          #    raise Exception, "[hiera-io_secrets] multiple groups were found, group name '#{@config[:group]}' not unique in vault"
          #  else
          #    raise Exception, "[hiera-io_secrets] no '#{@config[:group]}' group was found in vault"
          #  end
          #end

          # Secret Name Prep
          #secret_name = key.dup
          #secret_name.slice! "::io_secrets::"
          #secret_name = @prefix + secret_name unless @prefix.nil?
          #secret_name = secret_name + @suffix unless @suffix.nil?

          #oci_vault_ocid = Facter.value(:oci_vault_ocid)
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
