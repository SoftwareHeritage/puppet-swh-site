# Reverseproxy for netbox
class profile::netbox::reverse_proxy {
  ::profile::reverse_proxy {'netbox':
    extra_proxy_pass  => [{ patch => '/static', url => '!'}],
    extra_apache_opts => {
      proxy_preserve_host => true,
      aliases             => [
        { aliasmatch => '^/static',
          path       => "%{lookup('profile::netbox::install_path')}",
        },
      ],
    },
    icinga_check_uri  => '/login',
  }
}
