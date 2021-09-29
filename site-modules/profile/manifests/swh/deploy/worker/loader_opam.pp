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
      Package[$::profile::swh::deploy::loader_package::packages],
      Package[$packages],
    ],
  }

  $opam_instances = lookup('swh::deploy::worker::opam::instances')
  $template_path = "profile/swh/deploy/loader_opam"

  $opam_root = lookup('swh::deploy::worker::opam::root_directory')
  file {$opam_root:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    recurse => true,
    mode   => '0644',
  }

  $opam_manage_shared_state = "opam-manage-shared-state"
  $opam_manage_state_script = "/usr/local/bin/${opam_manage_shared_state}.sh"
  file {$opam_manage_state_script:
    ensure => 'file',
    owner  => $user,
    group  => $group,
    mode   => '0755',
    content => template("${template_path}/${opam_manage_shared_state}.sh.erb"),
  }

  each ( $opam_instances ) | $instance, $instance_url | {
    $opam_manage_service_name = "${$opam_manage_shared_state}-${instance}"
    $opam_manage_shared_state_timer_name = "${opam_manage_service_name}.timer"

    # Templates uses variables
    #  - $user
    #  - $group
    #  - $opam_root
    #  - $opam_manage_service_name
    #  - $command

    ::systemd::timer { $opam_manage_shared_state_timer_name:
      timer_content    => template("${template_path}/${opam_manage_shared_state}.timer.erb"),
      service_content  => template("${template_path}/${opam_manage_shared_state}.service.erb"),
      enable           => true,
      require          => [
        Package[$packages],
        File[$opam_root],
        File[$opam_manage_state_script],
      ],
    }
  }

}
