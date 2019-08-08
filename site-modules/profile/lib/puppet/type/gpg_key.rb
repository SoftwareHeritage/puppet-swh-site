Puppet::Type.newtype(:gpg_key) do
    ensurable
    @doc = "Creates and manages GPG keys"

    newparam(:uid, :namevar => true) do
      desc 'The uid for the generated key.'
    end

    newparam(:owner) do
      desc 'The owner of the generated key'
      validate do |owner|
        if !Puppet.features.root? && resource.current_username() != owner
          self.fail _("Only root can generate keys for other users")
        end
      end
    end

    newparam(:keytype) do
      desc 'Type of the generated primary key (default: RSA)'
      newvalues(:RSA, :DSA)
      defaultto :RSA
    end

    newparam(:keylength) do
      desc 'Length of the generated key in bits (default: 4096)'
      defaultto 4096

      munge do |value|
        case value
        when String
          value = Integer(value)
        end

        return value
      end
    end

    newparam(:expire) do
      desc 'Expiry of the generated key'
      defaultto '0'
    end

    newparam(:passphrase) do
      desc 'Passphrase for the generated key'
      defaultto ''
    end

    newproperty(:fingerprint) do
      desc %q{A read-only state to check the key fingerprint.}

      def retrieve
        current_value = :absent
        if fingerprint = provider.get_fingerprint
          current_value = fingerprint
        end
        current_value
      end

      validate do |val|
        fail 'fingerprint is read-only'
      end
    end

    newproperty(:public_key) do
      desc %q{A read-only state to get the public key.}

      def retrieve
        current_value = :absent
        if public_key = provider.get_public_key
          current_value = public_key
        end
        current_value
      end

      validate do |val|
        fail 'public_key is read-only'
      end
    end

    autorequire(:user) do
      if owner = self[:owner]
        owner
      end
    end

    def current_username
      Etc.getpwuid(Process.uid).name
    end
end
