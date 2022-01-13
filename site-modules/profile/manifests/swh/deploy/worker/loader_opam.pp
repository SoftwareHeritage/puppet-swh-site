# Deployment for opam loader
class profile::swh::deploy::worker::loader_opam {
  include ::profile::swh::deploy::worker::loader_package
  $private_tmp = lookup('swh::deploy::worker::loader_opam::private_tmp')

  $user = lookup('swh::deploy::worker::loader_opam::user')
  $group = lookup('swh::deploy::worker::loader_opam::group')

  $packages = ['opam']
  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_opam':
    ensure      => present,
    private_tmp => $private_tmp,
    sentry_name => 'loader_core',
    require     => [
      Package[$packages],
      Class['profile::swh::deploy::worker::loader_package'],
    ],
  }

  $opam_root = lookup('swh::deploy::worker::opam::root_directory')
  $opam_manage_shared_state = "opam-manage-shared-state"
  $opam_manage_state_script = "/usr/local/bin/${opam_manage_shared_state}.sh"

  # Install more robust opam root folder maintenance tooling
  $default_instance_name = lookup('swh::deploy::worker::opam::default_instance::name')
  $default_instance_url = lookup('swh::deploy::worker::opam::default_instance::url')
  $other_instances = lookup('swh::deploy::worker::opam::instances')

  $template_path = "profile/swh/deploy/loader_opam"

  # Templates uses variables
  # - $user
  # - $group
  # - $default_instance_name
  # - $default_instance_url
  # - $other_instances
  file {$opam_manage_state_script:
    ensure => 'file',
    owner  => $user,
    group  => $group,
    mode   => '0755',
    content => template("${template_path}/${opam_manage_shared_state}.sh.erb"),
  }

  # Templates uses variables
  # - $user
  # - $group
  # - $runparts_systemd_directory
  # - $opam_manage_service_name
  # - $opam_manage_state_script

  ::systemd::timer { "${opam_manage_shared_state}.timer":
    timer_content    => template("${template_path}/${opam_manage_shared_state}.timer.erb"),
    service_content  => template("${template_path}/${opam_manage_shared_state}.service.erb"),
    enable           => true,
    require          => [
      Package[$packages],
      File[$runparts_systemd_directory],
    ],
  }
}
