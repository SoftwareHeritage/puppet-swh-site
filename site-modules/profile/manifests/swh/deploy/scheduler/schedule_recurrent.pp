# Recurrent visit scheduler

class profile::swh::deploy::scheduler::schedule_recurrent {
  profile::swh::deploy::scheduler::service {"schedule-recurrent":
    service_description => "for recurrent visits",
    service_args        => ["schedule-recurrent"],
  }
}
