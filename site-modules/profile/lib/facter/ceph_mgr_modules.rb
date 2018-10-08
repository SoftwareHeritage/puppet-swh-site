require 'json'

Facter.add('ceph_mgr_modules') do
  setcode do
    if File.exist?('/var/lib/ceph/mgr')
      JSON.parse(Facter::Core::Execution.execute('ceph mgr module ls'))
    end
  end
end
