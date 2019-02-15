begin
	Facter.add("mounts") do
		ignorefs = [
      "NFS",
      "afs",
      "autofs",
      "binfmt_misc",
      "bpf",
      "cgroup",
      "cgroup2",
      "cifs",
      "coda",
      "configfs",
      "debugfs",
      "devfs",
      "devpts",
      "devtmpfs",
      "efivarfs",
      "ftpfs",
      "fuse",
      "fuse.gvfsd-fuse",
      "fuse.lxcfs",
      "fuse.snapshotfs",
      "fusectl",
      "hugetlbfs",
      "iso9660",
      "lustre_lite",
      "mfs",
      "mqueue",
      "ncpfs",
      "nfs",
      "nfs4",
      "nfsd",
      "proc",
      "pstore",
      "rpc_pipefs",
      "securityfs",
      "shfs",
      "smbfs",
      "sysfs",
      "tmpfs",
      "tracefs",
      "udf",
      "usbfs",
    ].uniq.sort.join(',')

		mountpoints = []

    Facter::Util::Resolution.exec("findmnt --list --noheadings -o TARGET,SOURCE --invert --types #{ignorefs}").lines.each do |line|
      mountpoint, source = line.chomp.split
      # bind mounts
      if not source.end_with?(']')
				mountpoints << mountpoint
      end
		end

		setcode do
			mountpoints
		end
  end

rescue Exception => _
end
