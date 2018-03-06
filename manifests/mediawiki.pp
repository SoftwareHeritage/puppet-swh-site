# Deployment of mediawiki for the Software Heritage intranet
class profile::mediawiki {
  $mediawiki_fpm_root = lookup('mediawiki::php::fpm_listen')

  $mediawiki_vhosts = lookup('mediawiki::vhosts', Hash, 'deep')

  include ::profile::php

  ::php::fpm::pool {'mediawiki':
    listen => $mediawiki_fpm_root,
    user   => 'www-data',
  }

  include ::profile::ssl

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  include ::mediawiki

  $mediawiki_vhost_docroot = lookup('mediawiki::vhost::docroot')
  $mediawiki_vhost_ssl_protocol = lookup('mediawiki::vhost::ssl_protocol')
  $mediawiki_vhost_ssl_honorcipherorder = lookup('mediawiki::vhost::ssl_honorcipherorder')
  $mediawiki_vhost_ssl_cipher = lookup('mediawiki::vhost::ssl_cipher')
  $mediawiki_vhost_hsts_header = lookup('mediawiki::vhost::hsts_header')

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  each ($mediawiki_vhosts) |$name, $data| {
    $secret_key = $data['secret_key']
    $upgrade_key = $data['upgrade_key']
    $site_name = $data['site_name']
    $basic_auth_content = $data['basic_auth_content']

    ::mediawiki::instance { $name:
      vhost_docroot              => $mediawiki_vhost_docroot,
      vhost_aliases              => $data['aliases'],
      vhost_fpm_root             => $mediawiki_fpm_root,
      vhost_basic_auth           => $basic_auth_content,
      vhost_ssl_protocol         => $mediawiki_vhost_ssl_protocol,
      vhost_ssl_honorcipherorder => $mediawiki_vhost_ssl_honorcipherorder,
      vhost_ssl_cipher           => $mediawiki_vhost_ssl_cipher,
      vhost_ssl_cert             => $ssl_cert,
      vhost_ssl_chain            => $ssl_chain,
      vhost_ssl_key              => $ssl_key,
      vhost_ssl_hsts_header      => $mediawiki_vhost_hsts_header,
      db_host                    => 'localhost',
      db_basename                => $data['mysql']['dbname'],
      db_user                    => $data['mysql']['username'],
      db_password                => $data['mysql']['password'],
      secret_key                 => $secret_key,
      upgrade_key                => $upgrade_key,
      swh_logo                   => $data['swh_logo'],
      site_name                  => $site_name,
    }

    @@::icinga2::object::service {"mediawiki (${name}) http redirect on ${::fqdn}":
      service_name  => "mediawiki ${name} http redirect",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_address => $name,
        http_vhost   => $name,
        http_uri     => '/',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }

    if $basic_auth_content != '' {
      $extra_vars = {
        http_expect => '401 Unauthorized',
      }

      @@::icinga2::object::service {"mediawiki ${name} https + auth on ${::fqdn}":
        service_name  => "mediawiki ${name} + auth",
        import        => ['generic-service'],
        host_name     => $::fqdn,
        check_command => 'http',
        vars          => {
          http_address    => $name,
          http_vhost      => $name,
          http_ssl        => true,
          http_sni        => true,
          http_uri        => '/',
          http_onredirect => sticky,
          http_auth_pair  => $data['icinga_http_auth_pair'],
          http_string     => "<title>${site_name}</title>",
        },
        target        => $icinga_checks_file,
        tag           => 'icinga2::exported',
      }

    } else {
      $extra_vars = {
        http_string => "<title>${site_name}</title>",
      }
    }

    @@::icinga2::object::service {"mediawiki ${name} https on ${::fqdn}":
      service_name  => "mediawiki ${name}",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_address    => $name,
        http_vhost      => $name,
        http_ssl        => true,
        http_sni        => true,
        http_uri        => '/',
        http_onredirect => sticky,
      } + $extra_vars,
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }

    @@::icinga2::object::service {"mediawiki ${name} https certificate ${::fqdn}":
      service_name  => "mediawiki ${name} https certificate",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_vhost       => $name,
        http_address     => $name,
        http_ssl         => true,
        http_sni         => true,
        http_certificate => 60,
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
