# Centralized borg repository server
class profile::borg::repository_server {
  Profile::Borg::Repository <| tag == $::swh_hostname['fqdn'] |>
}
