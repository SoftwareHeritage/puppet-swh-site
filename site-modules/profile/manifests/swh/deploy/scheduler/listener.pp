# scheduler listener
class profile::swh::deploy::scheduler::listener {
  profile::swh::deploy::scheduler::service {"listener":
    service_description => 'celery event listener',
    service_args        => ["start-listener"]
  }
}
