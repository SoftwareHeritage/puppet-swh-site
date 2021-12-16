# Enable mod_proxy_wstunnel
class profile::apache::mod_proxy_wstunnel {
  ::apache::mod {'proxy_wstunnel':}
}
