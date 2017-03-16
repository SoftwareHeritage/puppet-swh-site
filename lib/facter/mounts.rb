# from https://anonscm.debian.org/git/mirror/dsa-puppet.git/tree/modules/debian-org/lib/facter/mounts.rb

begin
  require 'filesystem'

	Facter.add("mounts") do
		ignorefs = [
      "NFS",
      "afs",
      "autofs",
      "binfmt_misc",
      "cifs",
      "coda",
      "devfs",
      "devpts",
      "devtmpfs",
      "ftpfs",
      "fuse.snapshotfs",
      "fusectl",
      "iso9660",
      "lustre_lite",
      "mfs",
      "ncpfs",
      "nfs",
      "nfs4",
      "nfsd",
      "proc",
      "rpc_pipefs",
      "shfs",
      "smbfs",
      "sysfs",
      "tmpfs",
      "udf",
      "usbfs",
    ]
		mountpoints = []
		FileSystem.mounts.each do |m|
			if ((not ignorefs.include?(m.fstype)) && (m.options !~ /bind/))
				mountpoints << m.mount
			end
		end
		setcode do
			mountpoints.uniq.sort.join(',')
		end
	end

rescue Exception => _
end
