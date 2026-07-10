# frozen_string_literal: true

# Fact: openbao_version
#
# Purpose: Check which version of openbao is currently installed
#
Facter.add(:openbao_version) do
  confine { Facter::Util::Resolution.which('bao') }
  setcode do
    openbao_version_output = Facter::Util::Resolution.exec('bao version')
    match = openbao_version_output.match(%r{openbao v(\d+\.\d+\.\d+)})
    match&.captures&.first
  end
end
