node /worker\d+\.softwareheritage\.org/ {
  include role::swh_worker
}

node default {
  include role::swh_server
}
