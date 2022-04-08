# Deployment for swh-loader-maven
class profile::swh::deploy::worker::loader_maven {
  include ::profile::swh::deploy::worker::loader_package

  ::profile::swh::deploy::worker::instance {'loader_maven':
    ensure      => present,
    sentry_name => 'loader_core',
  }
}
