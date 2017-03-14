require 'puppet'

Facter.add(:systemd_journal_puppet_hostcert) do
  setcode do
    Puppet.settings[:hostcert]
  end
end

Facter.add(:systemd_journal_puppet_hostprivkey) do
  setcode do
    Puppet.settings[:hostprivkey]
  end
end

Facter.add(:systemd_journal_puppet_localcacert) do
  setcode do
    Puppet.settings[:localcacert]
  end
end
