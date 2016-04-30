# Install passenger from package
class passenger::install (
  $passenger_name,
  $passenger_version,
  $passenger_provider = undef
  ) {

  if $passenger_version == '5' {
    case $::osfamily {
      'Debian' : { $require = Class['apt::update'] }
      'RedHat' : { $require = Yumrepo['passenger'] }
      default  : { fail('Not Supported') }
    }
  }

  ensure_packages($passenger_name,
    {
      'ensure'    => $passenger_version,
      'provider'  => $passenger_provider,
      'require'   => $require
    }
  )
}
