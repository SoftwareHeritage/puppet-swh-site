class profile::sentry::reverse_proxy {
  ::profile::reverse_proxy {'sentry':
    extra_apache_opts => {
      proxy_preserve_host => true,
    },
  }
}
