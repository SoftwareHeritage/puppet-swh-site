require 'json'

Facter.add('ceph_mgr_modules') do
  setcode do
    if File.exist?('/var/lib/ceph/mgr')
      data = Facter::Core::Execution.execute('ceph mgr module ls').strip
      if data
        JSON.parse(data)
      else
        {}
      end
    end
  end
end
