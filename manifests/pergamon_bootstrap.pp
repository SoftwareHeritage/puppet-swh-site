node 'pergamon.softwareheritage.org' {
  include profile::static_hostnames
  include profile::base
  include profile::ssh::server
  include profile::swh
  include profile::puppet
}
