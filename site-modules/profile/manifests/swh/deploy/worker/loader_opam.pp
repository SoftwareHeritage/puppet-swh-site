# Deployment for opam loader
class profile::swh::deploy::worker::loader_opam {
  include ::profile::swh::deploy::worker::loader_package
  $private_tmp = lookup('swh::deploy::worker::loader_opam::private_tmp')

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

  $opam_root = lookup('swh::deploy::worker::opam::root_directory')
  file {$opam_root:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    recurse => true,
    mode   => '0644',
  }

  $binary_cmd = "/usr/bin/opam"

  each ( $opam_instances ) | $instance, $instance_url | {
    $opam_manage_shared_state = "opam-manage-shared-state"
    $opam_manage_service_name = "${$opam_manage_shared_state}-${instance}"
    $opam_manage_shared_state_timer_name = "${opam_manage_service_name}.timer"

    # update the instance repository if present
    $update_command = "${binary_cmd} repo --all --root ${opam_root} | grep ${instance_url} && ${binary_cmd} update --root ${opam_root}"
    # common suffix command for the opam commands
    $command_suffix = "--root ${opam_root} ${instance} ${instance_url}"
    if $instance == "opam" {
      # Install the default rootdir for the main opam instance
      $install_command = "${binary_cmd} init --reinit --bare --no-setup ${command_suffix}"
    } else {
      # Other instances will just be added to the main opam root directory
      $install_command = "${binary_cmd} repository add ${command_suffix}"
    }

    # Either update the instance if present or install/add that new instance
    $opam_command = "( ${update_command} ) || ${install_command}"

    # Template uses variables
    #  - $user
    #  - $group
    #  - $opam_root
    #  - $opam_manage_service_name
    #  - $command
    ::systemd::timer { $opam_manage_shared_state_timer_name:
      timer_content    => template("profile/swh/deploy/loader_opam/${opam_manage_shared_state}.timer.erb"),
      service_content  => template("profile/swh/deploy/loader_opam/${opam_manage_shared_state}.service.erb"),
      enable           => true,
      require          => [
        Package[$packages],
        File[$opam_root],
      ],
    }
  }

}
