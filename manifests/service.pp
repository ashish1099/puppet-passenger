# Manage webservers
class passenger::service (
  $webserver = 'apache'
  ) {
  case $webserver {
    'apache' : { class { 'profile::apache': } }
    'nginx'  : { class { 'profile::nginx' : } }
    default  : { fail("Not Supported ${webserver}") }
  }
}
