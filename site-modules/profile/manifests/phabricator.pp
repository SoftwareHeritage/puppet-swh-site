# Setup an instance of phabricator
class profile::phabricator {
  $basepath = lookup('phabricator::basepath')
  $install_user = lookup('phabricator::user')
  $install_group = lookup('phabricator::group')
  $vcs_user = lookup('phabricator::vcs_user')

  $db_root_password = lookup('phabricator::mysql::root_password')
  $db_basename = lookup('phabricator::mysql::database_prefix')
  $db_user = lookup('phabricator::mysql::username')
  $db_password = lookup('phabricator::mysql::password')

  $db_ro_users = lookup('phabricator::mysql::readonly_usernames')
  $db_ro_pass_seed = lookup('phabricator::mysql::readonly_password_seed')


  $db_max_allowed_packet = lookup('phabricator::mysql::conf::max_allowed_packet')
  $db_sql_mode = lookup('phabricator::mysql::conf::sql_mode')
  $db_ft_stopword_file = lookup('phabricator::mysql::conf::ft_stopword_file')
  $db_ft_min_word_len = lookup('phabricator::mysql::conf::ft_min_word_len')
  $db_ft_boolean_syntax = lookup('phabricator::mysql::conf::ft_boolean_syntax')
  $db_innodb_buffer_pool_size = lookup('phabricator::mysql::conf::innodb_buffer_pool_size')
  $db_innodb_file_per_table = lookup('phabricator::mysql::conf::innodb_file_per_table')
  $db_innodb_flush_method = lookup('phabricator::mysql::conf::innodb_flush_method')
  $db_innodb_log_file_size = lookup('phabricator::mysql::conf::innodb_log_file_size')
  $db_max_connections = lookup('phabricator::mysql::conf::max_connections')

  $fpm_listen = lookup('phabricator::php::fpm_listen')
  $max_size = lookup('phabricator::php::max_file_size')
  $opcache_validate_timestamps = lookup('phabricator::php::opcache_validate_timestamps')

  $notification_listen = lookup('phabricator::notification::listen')
  $notification_client_host = lookup('phabricator::notification::client_host')
  $notification_client_port = lookup('phabricator::notification::client_port')

  $vhost_name = lookup('phabricator::vhost::name')
  $vhost_docroot = lookup('phabricator::vhost::docroot')
  $vhost_basic_auth_file = "${basepath}/http_auth"
  $vhost_basic_auth_content = lookup('phabricator::vhost::basic_auth_content')
  $vhost_ssl_protocol = lookup('phabricator::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('phabricator::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('phabricator::vhost::ssl_cipher')
  $vhost_hsts_header = lookup('phabricator::vhost::hsts_header')

  $homedirs = {
    $install_user => $basepath,
    $vcs_user     => "${basepath}/vcshome",
  }

  $homedir_modes = {
    $install_user => '0644',
    $vcs_user     => '0640',
  }

  $groups = {
    $install_user => $install_group,
  }

  group {$install_group:
    ensure => present,
    system => true,
  }

  each([$install_user, $vcs_user]) |$name| {
    user {$name:
      ensure => present,
      system => true,
      shell  => '/bin/bash',
      home   => $homedirs[$name],
      gid    => $groups[$name],
    }

    file {$homedirs[$name]:
      ensure => directory,
      owner  => $name,
      group  => $name,
      mode   => $homedir_modes[$name],
    }
  }

  ::sudo::conf {'phabricator-ssh':
    ensure  => present,
    content => "${vcs_user} ALL=(${install_user}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/hg",
  }

  ::sudo::conf {'phabricator-http':
    ensure  => present,
    content => "www-data ALL=(${install_user}) SETENV: NOPASSWD: /usr/bin/git-http-backend, /usr/bin/hg",
    require => File['/usr/bin/git-http-backend'],
  }

  file {'/usr/bin/git-http-backend':
    ensure => link,
    target => '/usr/lib/git-core/git-http-backend',
  }

  $ssh_hook = '/usr/bin/phabricator-ssh-hook.sh'
  $ssh_config = '/etc/ssh/ssh_config.phabricator'

  file {$ssh_hook:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/phabricator/phabricator-ssh-hook.sh.erb'),
  }

  # Uses:
    # $vcs_user
    # $ssh_hook
    # $db_ro_users
  file {$ssh_config:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('profile/phabricator/sshd_config.phabricator.erb'),
    require => File[$ssh_hook],
  }

  ::systemd::unit_file {'phabricator-sshd.service':
    ensure  => present,
    content => template('profile/phabricator/phabricator-sshd.service.erb'),
    require => File[$ssh_config],
  } ~> service {'phabricator-sshd':
    ensure  => 'running',
    enable  => true,
    require => [
      File['/etc/systemd/system/phabricator-sshd.service'],
    ],
  }

  include ::mysql::client

  class {'::mysql::server':
    root_password    => $db_root_password,
    override_options => {
      mysqld => {
        max_allowed_packet      => $db_max_allowed_packet,
        sql_mode                => $db_sql_mode,
        ft_stopword_file        => $db_ft_stopword_file,
        ft_min_word_len         => $db_ft_min_word_len,
        ft_boolean_syntax       => $db_ft_boolean_syntax,
        innodb_buffer_pool_size => $db_innodb_buffer_pool_size,
        innodb_file_per_table   => $db_innodb_file_per_table,
        innodb_flush_method     => $db_innodb_flush_method,
        innodb_log_file_size    => $db_innodb_log_file_size,
        max_connections         => $db_max_connections,
        local_infile            => 0,
      }
    }
  }

  $mysql_username = "${db_user}@localhost"
  $mysql_tables = "${db_basename}_%.*"

  mysql_user {$mysql_username:
    ensure        => present,
    password_hash => mysql_password($db_password),
  }

  mysql_grant {"${mysql_username}/${mysql_tables}":
    user       => $mysql_username,
    table      => $mysql_tables,
    privileges => ['ALL'],
    require    => Mysql_user[$mysql_username],
  }

  $db_ro_users.each |$db_ro_user| {
    $full_username = "${db_ro_user}@localhost"
    $db_ro_password = fqdn_rand_string(16, '', "phabricator::mysql::${db_ro_user}::${db_ro_pass_seed}")
    mysql_user {$full_username:
      ensure        => present,
      password_hash => mysql_password($db_ro_password),
    }

    mysql_grant {"${full_username}/${mysql_tables}":
      user       => $full_username,
      table      => $mysql_tables,
      privileges => ['SELECT', 'SHOW VIEW'],
      require    => Mysql_user[$full_username],
    }

    $user_definition = $profile::base::users[$db_ro_user]

    if $user_definition {
      file {"/home/${db_ro_user}/.my.cnf":
        ensure  => present,
        mode    => '0400',
        owner   => $db_ro_user,
        content => "# Generated by puppet. Changes will be lost!\n\n[client]\nuser=${db_ro_user}\nhost=localhost\npassword=${db_ro_password}\n",
      }
    }
  }

  include ::profile::php

  ::php::fpm::pool {'phabricator':
    listen          => $fpm_listen,
    user            => 'www-data',
    php_admin_value => {
      post_max_size                 => $max_size,
      upload_max_filesize           => $max_size,
      'opcache.validate_timestamps' => $opcache_validate_timestamps,
      'mysqli.allow_local_infile'   => 0,
    },
  }

  ::php::extension {[
    'apcu',
    'mailparse',
  ]:
    provider       => 'apt',
    package_prefix => 'php-',
  }

  ::php::extension {[
    'curl',
    'gd',
    'mbstring',
    'zip',
  ]:
    provider => 'apt',
  }

  include ::profile::apache::common
  include ::apache::mod::proxy
  include ::profile::apache::mod_proxy_fcgi

  ::apache::mod {'proxy_wstunnel':}

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $vhost_docroot,
    docroot_owner   => $install_user,
    docroot_group   => $install_user,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }


  ::profile::letsencrypt::certificate {$vhost_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($vhost_name)

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
    headers              => [$vhost_hsts_header],
    docroot              => $vhost_docroot,
    docroot_owner        => $install_user,
    docroot_group        => $install_user,
    rewrites             => [
      { rewrite_rule => '^/rsrc/(.*) - [L,QSA]' },
      { rewrite_rule => '^/favicon.ico - [L,QSA]' },
      { rewrite_rule => "^/ws/(.*)$ ws://${notification_listen}/\$1 [L,P]" },
      { rewrite_rule => "^(.*)$ fcgi://${fpm_listen}${vhost_docroot}/index.php?__path__=\$1 [B,L,P,QSA]" },
    ],
    setenvif             => [
      "Authorization \"(.*)\" HTTP_AUTHORIZATION=\$1",
    ],
    require              => [
      File[$cert_paths['cert']],
      File[$cert_paths['chain']],
      File[$cert_paths['privkey']],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  file {$vhost_basic_auth_file:
    ensure  => absent,
  }

  # Uses:
    # $basepath
    # $install_user
  ::systemd::unit_file {'phabricator-phd.service':
    ensure  => present,
    content => template('profile/phabricator/phabricator-phd.service.erb'),
  } ~> service {'phabricator-phd':
    ensure => 'running',
    enable => true,
  }

  # Uses:
    # $basepath
    # $install_user
    # $notification_*
  ::systemd::unit_file {'phabricator-aphlict.service':
    ensure  => present,
    content => template('profile/phabricator/phabricator-aphlict.service.erb'),
  } ~> service {'phabricator-aphlict':
      ensure => 'running',
      enable => true,
  }

  package {'python-pygments':
    ensure => installed,
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  @@::icinga2::object::service {"phabricator http redirect on ${::fqdn}":
    service_name  => 'phabricator http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"phabricator https on ${::fqdn}":
    service_name  => 'phabricator',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $vhost_name,
      http_vhost      => $vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"phabricator https certificate ${::fqdn}":
    service_name  => 'phabricator https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $vhost_name,
      http_vhost       => $vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 25,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  # Needs refactoring
  $ssh_known_hosts_dir = '/etc/ssh/puppet_known_hosts'
  $ssh_known_hosts_target = "${ssh_known_hosts_dir}/${::fqdn}.keys"

  each($::ssh) |$algo, $data| {
    $real_algo = $algo ? {
      'ecdsa' => 'ecdsa-sha2-nistp256',
      default => $algo,
    }
    @@::concat::fragment {"ssh-phabricator-${::fqdn}-${real_algo}":
      target  => $ssh_known_hosts_target,
      content => inline_template("<%= @vhost_name %> <%= @real_algo %> <%= @data['key'] %>\n"),
      order   => '20',
      tag     => 'ssh_known_hosts',
    }
  }
}
