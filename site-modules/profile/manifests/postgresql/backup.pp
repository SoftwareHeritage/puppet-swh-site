class profile::postgresql::backup {
	include profile::postgresql::client

	$pg_backup_user = %{hiera('swh::deploy::db::pgbouncer::user::login')}
	$pg_backup_password = %{hiera('swh::deploy::db::pgbouncer::user::password')}

	file { '/usr/local/bin/pg_cluster_backup.sh':
		ensure	=> file,
		owner	=> root,
		group	=> staff,
		mode	=> '0755',
		content => template('profile/swh/pg_cluster_backup.sh.erb'),
	}

}
