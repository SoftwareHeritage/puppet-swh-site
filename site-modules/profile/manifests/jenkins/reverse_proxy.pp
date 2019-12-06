class profile::jenkins::reverse_proxy {
  ::profile::reverse_proxy {'jenkins':
    default_proxy_pass_opts => {
      keywords => ['nocanon'],
    },
    extra_apache_opts       => {
      allow_encoded_slashes => 'nodecode',
    },
  }
}
