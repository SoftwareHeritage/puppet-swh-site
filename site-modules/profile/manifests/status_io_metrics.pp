# status.io metrics tools
class profile::status_io_metrics {

  $packages = ['python3-click', 'python3-requests', 'python3-statusio']

  ensure_packages($packages)

  $script_name = 'statusio_export_archive_counters.py'
  $script_path = "/usr/local/bin/${script_name}"

  $prometheus_server = 'thanos.internal.admin.swh.network'
  $prometheus_port = 19191

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
    '--api-id ${API_ID}',
    '--api-key ${API_KEY}',
    '--status-page-id ${STATUS_IO_PAGE_ID}',
    '--metric-id ${STATUS_IO_METRICS_ID}',
    '-q "sum(rabbitmq_queue_messages{environment=\"production\", queue=~\"save_code_now.*\"})"',
    "-s ${prometheus_server}",
    "-p ${prometheus_port}",
  ]

  $parameters = join($script_params, ' ')

  profile::cron::environment { 'status_scn_metrics':
    target    => 'statusio_scn_metrics',
    variables => {
        'API_ID'  => $statusio_api_id,
        'API_KEY' => $statusio_api_key,
        'STATUS_IO_PAGE_ID' => $statusio_status_page,
        'STATUS_IO_METRICS_ID' => $statusio_scn_metrics,
    }
  }

  profile::cron::d {'statusio_scn_metrics':

    target  => 'statusio_scn_metrics',
    command => "chronic sh -c '${script_path} ${parameters}'  ",
    minute  => '*/5',
    hour    => '*',
  }

}
