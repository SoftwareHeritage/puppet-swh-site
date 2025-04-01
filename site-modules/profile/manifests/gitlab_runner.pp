class profile::gitlab_runner {

  $manage_runner = lookup('gitlab_runner::managed', default_value => true)

  if $manage_runner {

    $gitlab_url = lookup('gitlab_runner::gitlab_url')
    $runner_name = lookup('gitlab_runner::name')
    $runner_registration_token = lookup("gitlab_runner::${runner_name}::registration_token")
    $runner_concurrent = lookup('gitlab_runner::concurrent')
    $runner_docker_image = lookup('gitlab_runner::docker::image')

    gitlab_ci_runner::runner { 'gitlab-runner':
      config => {
        url           =>  $gitlab_url,
        token         => Deferred('gitlab_ci_runner::register_runner_to_file', [$gitlab_url, $runner_registration_token, $runner_name]),
        name          => $runner_name,
        executor      => 'docker',
        manage_docker => false,
        docker        => {
          image                 => $runner_docker_image,
          allowed_pull_policies => ["always", "if-not-present"]
        },
      },
    }
  }
}
