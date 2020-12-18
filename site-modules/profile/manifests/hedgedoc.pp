# deploy a hedgedoc instance
class profile::hedgedoc {

  $packages = [
    'npm', 'yarnpkg', 'node-gyp'
  ]

  ensure_packages ( $packages )

}
