class profile::jenkins::reverse_proxy {
  include ::profile::apache::mod_proxy_wstunnel

  $jenkins_ws_url = lookup('jenkins::backend::ws_url')

  $jenkins_vhost_name = lookup('jenkins::vhost::name')
  ::profile::reverse_proxy {'jenkins':
    default_proxy_pass_opts => {
      keywords => ['nocanon'],
    },
    extra_apache_opts       => {
      allow_encoded_slashes => 'nodecode',
    },
    extra_proxy_pass        => [
      { path     => '/wsagents',
        url      => "${jenkins_ws_url}wsagents",
        keywords => ['nocanon'],
      },
    ],
  }

  profile::prometheus::export_scrape_config {"jenkins_${jenkins_vhost_name}":
    job          => "jenkins",
    target       => "${jenkins_vhost_name}:443",
    scheme       => "https",
    metrics_path => '/prometheus',
    labels       => {
      instance => $jenkins_vhost_name,
    },
  }
}
