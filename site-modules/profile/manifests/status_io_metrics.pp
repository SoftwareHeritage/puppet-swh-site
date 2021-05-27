# status.io metrics tools
class profile::status_io_metrics {

  $packages = ['python3-click', 'python3-requests', 'python3-statusio']

  ensure_packages($packages)

  $script_name = 'statusio_export_archive_counters.py'
  $script_path = "/usr/local/bin/${script_name}"

  $prometheus_server = 'pergamon.internal.softwareheritage.org'
  $prometheus_port = 9090

  $statusio_api_id = lookup('status_io::api_id')
  $statusio_api_key = lookup('status_io::api_key')
  $statusio_status_page = lookup('status_io::status_page')
  $statusio_scn_metrics = lookup('status_io::metrics::scn')

  file {$script_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => "puppet:///modules/profile/status.io/${script_name}",
    require => Package[$packages],
  }

  $script_params = [
    '-m swh_web_accepted_save_requests',
    "--api-id ${statusio_api_id}",
    "--api-key ${statusio_api_key}",
    "--status-page-id ${statusio_status_page}",
    "--metric-id ${statusio_scn_metrics}",
    '-f environment=production',
    '-f "load_task_status=~scheduled|not_yet_scheduled"',
    '-f instance=moma.internal.softwareheritage.org',
  ]

  $parameters = join($script_params, ' ')

  profile::cron::d {'statusio_scn_metrics':
    target  => 'statusio_scn_metrics',
    command => "chronic sh -c '${script_path} ${parameters}'  ",
    minute  => '*/5',
    hour    => '*',
  }

}
