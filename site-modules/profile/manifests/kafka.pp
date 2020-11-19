# Base configuration for kafka
class profile::kafka {
  include ::java

  class {'::kafka':
    mirror_url    => lookup('kafka::mirror_url'),
    version       => lookup('kafka::version'),
    scala_version => lookup('kafka::scala_version'),
  }
}
