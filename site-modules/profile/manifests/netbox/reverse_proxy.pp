# Reverseproxy for netbox
class profile::netbox::reverse_proxy {
  $install_path = $::profile::netbox::install_path
  $static_path = "${install_path}/netbox/static"

  ::profile::reverse_proxy {'netbox':
    extra_apache_opts   => {
      proxy_preserve_host => true,
      aliases             => [
        { alias => '/static',
          path  => $static_path,
        },
      ],
      directories         => [ {
        path       => '/static',
        provider   => 'location',
        proxy_pass => [ { url => '!' } ],
      }, {
        path     => $static_path,
        provider => 'directory',
        options  => ['Indexes','FollowSymLinks','MultiViews'],
      }
    ]    },
    icinga_check_uri    => '/login/',
    icinga_check_string => 'NetBox',
  }
}
