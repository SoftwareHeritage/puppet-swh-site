# Handle specific kubernetes setup
class profile::kubernetes {
  $max_map_count = lookup("kubernetes::max_map_count")
  $inotify_max_user_instances = lookup("kubernetes::inotify_max_user_instances")
  $inotify_max_user_watches = lookup("kubernetes::inotify_max_user_watches")
  # needed for specific workload (e.g. elasticsearch, rancher, ...)
  sysctl { 'vm.max_map_count': value => $max_map_count }
  sysctl { 'fs.inotify.max_user_instances': value => $inotify_max_user_instances }
  sysctl { 'fs.inotify.max_user_watches': value => $inotify_max_user_watches }
}
