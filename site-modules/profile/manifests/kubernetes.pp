# Handle specific kubernetes setup
class profile::kubernetes {
  # needed for specific workload like elasticsearch
  sysctl { 'vm.max_map_count': value => '2097152' }
}
