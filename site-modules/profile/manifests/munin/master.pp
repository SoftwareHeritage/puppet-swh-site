# Munin master class
class profile::munin::master {
  $master_hostname = lookup('munin::master::hostname')
  $master_hostname_domain = join(delete_at(split($master_hostname, '[.]'), 0), '.')
  $master_hostname_target = "${::hostname}.${master_hostname_domain}."

  class { '::munin::master':
    extra_config => ["cgiurl_graph http://$master_hostname"],
  }

  $export_path = lookup('stats_export::export_path')

  file {$export_path:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  } ~> Apache::Vhost[$master_hostname]

  include ::profile::apache::common
  include ::apache::mod::rewrite
  include ::apache::mod::fcgid

  apache::vhost { $master_hostname:
    port        => 80,
    docroot     => '/var/www/html',
    rewrites    => [
      {
        comment      => 'static resources',
        rewrite_rule => [
          '^/favicon.ico /etc/munin/static/favicon.ico [L]',
          '^/static/(.*) /etc/munin/static/$1          [L]',
          "^/export/(.*) ${export_path}/\$1       [L]",
        ],
      },
      {
        comment      => 'HTML',
        rewrite_cond => [
          '%{REQUEST_URI} .html$ [or]',
          '%{REQUEST_URI} =/',
        ],
        rewrite_rule => [
          '^/(.*)          /usr/lib/munin/cgi/munin-cgi-html/$1 [L]',
        ],
      },
      {
        comment      => 'Images',
        rewrite_rule => [
          '^/munin-cgi/munin-cgi-graph/(.*) /usr/lib/munin/cgi/munin-cgi-graph/$1 [L]',
          '^/(.*) /usr/lib/munin/cgi/munin-cgi-graph/$1 [L]',
        ],
      },
    ],
    directories => [
      { 'path'       => '/usr/lib/munin/cgi',
        'options'    => '+ExecCGI',
        'sethandler' => 'fcgid-script'
      },
      { 'path'       => "${export_path}",
        'options'    => '+Indexes',  # allow listing
      }
    ],
  }

}
