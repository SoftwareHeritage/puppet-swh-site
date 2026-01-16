class profile::apache::common {
  include ::apache
  include ::apache::mod::status

  include ::profile::prometheus::apache
}
