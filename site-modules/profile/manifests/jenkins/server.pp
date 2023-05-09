class profile::jenkins::server {
  include profile::jenkins::service

  file { "/usr/local/bin/clean-docker-images.sh":
    ensure => present,
    source => 'puppet:///modules/profile/jenkins/clean-docker-images.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
