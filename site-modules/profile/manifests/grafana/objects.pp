# Creation of grafana objects

class profile::grafana::objects {
  $grafana_vhost = lookup('grafana::vhost::name')
  $grafana_url = "https://${grafana_vhost}"
  $grafana_user = 'admin'
  $grafana_password = lookup("grafana::user::${grafana_user}::password")

  $orgs = lookup('grafana::objects::organizations')

  each($orgs) |$org| {
    grafana_organization {$org['name']:
      grafana_url      => $grafana_url,
      grafana_user     => $grafana_user,
      grafana_password => $grafana_password,
      *                => $org - 'name',
    }
  }

  $users = lookup('grafana::objects::users')

  each($users) |$user| {
    $username = $user['username']
    $user_password = lookup("grafana::user::${username}::password")
    grafana_user {$user['username']:
      grafana_url      => $grafana_url,
      grafana_user     => $grafana_user,
      grafana_password => $grafana_password,
      password         => $user_password,
      *                => $user - 'username',
    }
  }

  $datasources = lookup('grafana::objects::datasources')

  each($datasources) |$datasource| {
    grafana_datasource {$datasource['name']:
      grafana_url      => $grafana_url,
      grafana_user     => $grafana_user,
      grafana_password => $grafana_password,
      *                => $datasource - 'name',
    }
  }
}
