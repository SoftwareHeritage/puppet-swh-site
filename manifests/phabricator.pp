# Setup an instance of phabricator
class profile::phabricator {
  $phabricator_basepath = hiera('phabricator::basepath')
  $phabricator_user = hiera('phabricator::user')
  $phabricator_vcs_user = hiera('phabricator::vcs_user')

  $phabricator_db_root_password = hiera('phabricator::mysql::root_password')
  $phabricator_db_basename = hiera('phabricator::mysql::database_prefix')
  $phabricator_db_user = hiera('phabricator::mysql::username')
  $phabricator_db_password = hiera('phabricator::mysql::password')

  $phabricator_db_max_allowed_packet = hiera('phabricator::mysql::conf::max_allowed_packet')
  $phabricator_db_sql_mode = hiera('phabricator::mysql::conf::sql_mode')
  $phabricator_db_ft_stopword_file = hiera('phabricator::mysql::conf::ft_stopword_file')
  $phabricator_db_ft_min_word_len = hiera('phabricator::mysql::conf::ft_min_word_len')
  $phabricator_db_ft_boolean_syntax = hiera('phabricator::mysql::conf::ft_boolean_syntax')
  $phabricator_db_innodb_buffer_pool_size = hiera('phabricator::mysql::conf::innodb_buffer_pool_size')
  $phabricator_db_innodb_file_per_table = hiera('phabricator::mysql::conf::innodb_file_per_table')
  $phabricator_db_innodb_flush_method = hiera('phabricator::mysql::conf::innodb_flush_method')
  $phabricator_db_innodb_log_file_size = hiera('phabricator::mysql::conf::innodb_log_file_size')

  $phabricator_fpm_listen = hiera('phabricator::php::fpm_listen')
  $phabricator_max_size = hiera('phabricator::php::max_file_size')
  $phabricator_opcache_validate_timestamps = hiera('phabricator::php::opcache_validate_timestamps')

  $phabricator_notification_listen = hiera('phabricator::notification::listen')

  $phabricator_vhost_name = hiera('phabricator::vhost::name')
  $phabricator_vhost_docroot = hiera('phabricator::vhost::docroot')
  $phabricator_vhost_basic_auth_file = "${phabricator_basepath}/http_auth"
  $phabricator_vhost_basic_auth_content = hiera('phabricator::vhost::basic_auth_content')
  $phabricator_vhost_ssl_protocol = hiera('phabricator::vhost::ssl_protocol')
  $phabricator_vhost_ssl_honorcipherorder = hiera('phabricator::vhost::ssl_honorcipherorder')
  $phabricator_vhost_ssl_cipher = hiera('phabricator::vhost::ssl_cipher')
  $phabricator_vhost_hsts_header = hiera('phabricator::vhost::hsts_header')

  include ::systemd

  $homedirs = {
    $phabricator_user     => $phabricator_basepath,
    $phabricator_vcs_user => "${phabricator_basepath}/vcshome",
  }

  $homedir_modes = {
    $phabricator_user     => '0644',
    $phabricator_vcs_user => '0640',
  }

  each([$phabricator_user, $phabricator_vcs_user]) |$name| {
    user {$name:
      ensure => present,
      system => true,
      shell  => '/bin/bash',
      home   => $homedirs[$name],
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
    content => "${phabricator_vcs_user} ALL=(${phabricator_user}) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/hg",
  }

  ::sudo::conf {'phabricator-http':
    ensure  => present,
    content => "www-data ALL=(${phabricator_user}) SETENV: NOPASSWD: /usr/bin/git-http-backend, /usr/bin/hg",
    require => File['/usr/bin/git-http-backend'],
  }

  file {'/usr/bin/git-http-backend':
    ensure => link,
    target => '/usr/lib/git-core/git-http-backend',
  }

  $phabricator_ssh_hook = '/usr/bin/phabricator-ssh-hook.sh'
  $phabricator_ssh_config = '/etc/ssh/ssh_config.phabricator'

  file {$phabricator_ssh_hook:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/phabricator/phabricator-ssh-hook.sh.erb'),
  }

  file {$phabricator_ssh_config:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('profile/phabricator/sshd_config.phabricator.erb'),
    require => File[$phabricator_ssh_hook],
  }

  file {'/etc/systemd/system/phabricator-sshd.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/phabricator/phabricator-sshd.service.erb'),
    notify  => Exec['systemd-daemon-reload'],
    require => File[$phabricator_ssh_config],
  }

  service {'phabricator-sshd':
    ensure  => 'running',
    enable  => true,
    require => [
      File['/etc/systemd/system/phabricator-sshd.service'],
      Exec['systemd-daemon-reload'],
    ],
  }

  include ::mysql::client

  class {'::mysql::server':
    root_password    => $phabricator_db_root_password,
    override_options => {
      mysqld => {
        max_allowed_packet      => $phabricator_db_max_allowed_packet,
        sql_mode                => $phabricator_db_sql_mode,
        ft_stopword_file        => $phabricator_db_ft_stopword_file,
        ft_min_word_len         => $phabricator_db_ft_min_word_len,
        ft_boolean_syntax       => $phabricator_db_ft_boolean_syntax,
        innodb_buffer_pool_size => $phabricator_db_innodb_buffer_pool_size,
        innodb_file_per_table   => $phabricator_db_innodb_file_per_table,
        innodb_flush_method     => $phabricator_db_innodb_flush_method,
        innodb_log_file_size    => $phabricator_db_innodb_log_file_size,
      }
    }
  }

  $mysql_username = "${phabricator_db_user}@localhost"
  $mysql_tables = "${phabricator_db_basename}_%.*"

  mysql_user {$mysql_username:
    ensure        => present,
    password_hash => mysql_password($phabricator_db_password),
  }

  mysql_grant {"${mysql_username}/${mysql_tables}":
    user       => $mysql_username,
    table      => $mysql_tables,
    privileges => ['ALL'],
    require    => Mysql_user[$mysql_username],
  }

  include ::php::cli

  include ::php::fpm::daemon

  ::php::ini {'/etc/php5/cli/php.ini':}

  ::php::fpm::conf {'phabricator':
    listen          => $phabricator_fpm_listen,
    user            => 'www-data',
    php_admin_value => {
      post_max_size                 => $phabricator_max_size,
      upload_max_filesize           => $phabricator_max_size,
      'opcache.validate_timestamps' => $phabricator_opcache_validate_timestamps,
    },
  }

  ::php::module {[
    'apcu',
    'curl',
    'gd',
    'mailparse',
    'mysql',
  ]:
  }

  include ::profile::ssl
  include ::apache
  include ::apache::mod::proxy
  include ::profile::apache::mod_proxy_fcgi

  ::apache::mod {'proxy_wstunnel':}

  ::apache::vhost {"${phabricator_vhost_name}_non-ssl":
    servername      => $phabricator_vhost_name,
    port            => '80',
    docroot         => $phabricator_vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${phabricator_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${phabricator_vhost_name}_ssl":
    servername           => $phabricator_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $phabricator_vhost_ssl_protocol,
    ssl_honorcipherorder => $phabricator_vhost_ssl_honorcipherorder,
    ssl_cipher           => $phabricator_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_ca               => $ssl_ca,
    ssl_key              => $ssl_key,
    headers              => [$phabricator_vhost_hsts_header],
    docroot              => $phabricator_vhost_docroot,
    rewrites             => [
      { rewrite_rule => '^/rsrc/(.*) - [L,QSA]' },
      { rewrite_rule => '^/favicon.ico - [L,QSA]' },
      { rewrite_rule => "^/ws/(.*)$ ws://${phabricator_notification_listen}/\$1 [L,P]" },
      { rewrite_rule => "^(.*)$ fcgi://${phabricator_fpm_listen}${phabricator_vhost_docroot}/index.php?__path__=\$1 [B,L,P,QSA]" },
    ],
    directories          => [
      { path           => '/',
        provider       => 'location',
        auth_type      => 'Basic',
        auth_name      => 'Software Heritage development',
        auth_user_file => $phabricator_vhost_basic_auth_file,
        auth_require   => 'valid-user',
      },
    ],
    require              => [
        File[$phabricator_vhost_basic_auth_file],
        File[$ssl_cert],
        File[$ssl_ca],
        File[$ssl_key],
    ],
  }

  file {$phabricator_vhost_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => $phabricator_vhost_basic_auth_content,
  }

  # Uses:
    # $phabricator_basepath
    # $phabricator_user
  file {'/etc/systemd/system/phabricator-phd.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/phabricator/phabricator-phd.service.erb'),
    notify  => Exec['systemd-daemon-reload'],
  }

  service {'phabricator-phd':
    ensure  => 'running',
    enable  => true,
    require => [
      File['/etc/systemd/system/phabricator-phd.service'],
      Exec['systemd-daemon-reload'],
    ],
  }

  package {'python-pygments':
    ensure => installed,
  }
}
