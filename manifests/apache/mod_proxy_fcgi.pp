# Profile for apache mod proxy fcgi
class profile::apache::mod_proxy_fcgi {
  include ::profile::apache::common
  ::apache::mod {'proxy_fcgi':}
}
