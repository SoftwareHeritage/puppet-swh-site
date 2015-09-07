class profile::worker::deploy_key {

  $worker_user = hiera('worker::deploy::user')

  file {"/home/${worker_user}/.ssh/id_rsa":
    ensure  => present,
    content => hiera('worker::deploy::private_key'),
    owner   => $worker_user,
    group   => $worker_user,
    mode    => '0400',
    require => [
      User[$worker_user],
      File["/home/${worker_user}/.ssh"],
    ],
  }

  file {"/home/${worker_user}/.ssh/id_rsa.pub":
    ensure  => present,
    content => hiera('worker::deploy::public_key'),
    owner   => $worker_user,
    group   => $worker_user,
    mode    => '0400',
    require => [
      User[$worker_user],
      File["/home/${worker_user}/.ssh"],
    ],
  }
}
