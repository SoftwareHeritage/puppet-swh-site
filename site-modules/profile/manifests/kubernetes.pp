# Handle specific kubernetes setup
class profile::kubernetes {
  $max_map_count = lookup("kubernetes::max_map_count")
  $inotify_max_user_instances = lookup("kubernetes::inotify_max_user_instances")
  # needed for specific workload like elasticsearch
  sysctl { 'vm.max_map_count': value => $max_map_count }
  sysctl { 'fs.inotify.max_user_instances': value => $inotify_max_user_instances }
}
