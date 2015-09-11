# Deployment of the deployment private key for Software Heritage

class profile::swh::deploy {
  $deploy_group = hiera('swh::deploy::group')
  $deploy_directory = hiera('swh::deploy::dirctory')

  file {$deploy_directory:
    ensure  => directory,
    owner   => 'root',
    group   => $deploy_group,
    mode    => '0750',
    require => [
      Group[$deploy_group],
    ]
  }

  file {"${deploy_directory}/id_rsa":
    ensure  => present,
    content => hiera('worker::deploy::private_key'),
    owner   => 'root',
    group   => $deploy_group,
    mode    => '0640',
    require => [
      File[$deploy_directory],
      Group[$deploy_group],
    ],
  }

  file {"${deploy_directory}/id_rsa.pub":
    ensure  => present,
    content => hiera('worker::deploy::public_key'),
    owner   => 'root',
    group   => $deploy_group,
    mode    => '0640',
    require => [
      File[$deploy_directory],
      Group[$deploy_group],
    ],
  }
}
