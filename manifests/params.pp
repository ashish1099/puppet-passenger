# Default params
class passenger::params {
  $passenger_ruby     = '/usr/bin/ruby'

  # Default values for package installation
  case $::passenger::passenger_version {
    default : {
      case $::osfamily {
        'RedHat' : {
          # This is directory is needed in redhat for passenger 5
          file { '/var/run/passenger-instreg' :
            ensure => directory,
            mode   => '0755'
          }

          $mod_passenger  = '/usr/lib64/httpd/modules/mod_passenger.so'

          # Different location of passenger_root under centos6
          if $::operatingsystemmajrelease == '6' {
            $passenger_root = '/usr/lib/ruby/1.8/phusion_passenger/locations.ini'
          } else {
            $passenger_root = '/usr/share/ruby/vendor_ruby/phusion_passenger/locations.ini'
          }
        }
        'Debian' : {
          $mod_passenger = '/usr/lib/apache2/modules/mod_passenger.so'
          $passenger_root = '/usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini'
        }
        default : { fail('Not Supported') }
      }
    }
    '4' : {
      case $::osfamily {
        'RedHat' : {
          $mod_passenger  = '/usr/lib64/httpd/modules/mod_passenger.so'
          $passenger_root = "/usr/lib/ruby/gems/1.8/gems/passenger-${::passenger_version}"
        }
        'Debian' : {
          fail('Debian family not supported for passenger_version 4 from package installation, Please setup using gem provider')
        }
        default : { fail('Not Supported') }
      }
    }
  }
}
