# APT configuration for Elastic.co

class profile::elastic::apt_config {
  # Elasticsearch official package installation instructions:
  # https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html
  $keyring_url = lookup('elastic::apt_config::keyring::url')

  $versions = [lookup('elastic::elk_version'), lookup('elastic::beat_version')]

  $major_versions = $versions.map |$version| { $version.split('[.]')[0] }.unique
  apt::keyring { 'elasticsearch-keyring.asc':
    source => $keyring_url,
  }

  $major_versions.each |$major_version| {
    apt::source { "elastic-${major_version}.x":
      location => "https://artifacts.elastic.co/packages/${major_version}.x/apt",
      release  => 'stable',
      repos    => 'main',
      keyring  => '/etc/apt/keyrings/elasticsearch-keyring.asc',
    }
  }

  $removed_major_versions = ['6', '7', '8', '9'] - $major_versions
  $removed_sources = ['elasticsearch'] + $removed_major_versions.map |$v| { "elastic-${v}.x" }

  apt::source {$removed_sources:
    ensure => absent,
  }
}
