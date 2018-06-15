class profile::apache::common {
  include ::apache
  include ::apache::mod::status
  include ::profile::munin::plugins::apache
}
