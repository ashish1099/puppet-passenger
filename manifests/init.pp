# == Class: passenger
#
# This class install passenger version 5 by default.
# http://www.modrails.com
# Some of the files are simply copied from puppetlabs-passenger 
#
# === Parameters
#
# Document parameters here.
#
# [*passenger_name*]
#   The name of the package, default to *passenger*
#
# [*passenger_version*]
#   The passenger version, currently support are 4 and 5 [ Defaults to *5* ]
#
# [*passenger_provider*]
#   The provider to install passenger, gem or package [ Default to package ]
# 
# [*compile*]
#   Do you want to compile apache or nginx with passenger [ Defaults to *apache* ]
# 
# [*manage_web_server*]
#   Do you want to manage web server by passenger [ Default to true ]
#
# === Examples
#
#  class { 'passenger': }
#
#  class { "::passenger" :
#    compile             => 'apache',
#    passenger_name      => 'passenger',
#    passenger_version   => '5',
#    passenger_provider  => 'package'
#    manage_web_server   => false
#  }
#
# === Authors
#
# Ashish Jaiswal <ashish1099@gmail.com>
#
# === Copyright
#
# Copyright 2015 Ashish Jaiswal, unless otherwise noted.
#
class passenger (
  $passenger_name       = 'passenger',
  $passenger_version    = '5',
  $passenger_provider   = 'package',
  $compile              = 'apache',
  $manage_web_server    = false
  ) {

  include passenger::params

  # Validate repo and web_server
  validate_bool($manage_web_server)

  # Validate the passenger_provider
  validate_re($passenger_provider, [ '^package', '^gem' ], "${passenger_provider} is not supported, Please choose \"gem\" or \"package\" provider")

  # Validate the passenger_version
  validate_re($passenger_version, [ '5', '4' ], "${passenger_version} is not supported, Please choose version 4 or version 5")

  # Validate the web server
  validate_re($compile, [ 'apache' ], "${compile} is not supported as of now, Please choose apache web server")

  case $passenger_provider {
    'package' : {

      #TODO
      # Support passenger_version 3

      case $passenger_version {
        '5' : {

          # Setup Repository
          class { 'passenger::repo' : notify => Class['passenger::install'] }

          $_passenger_name    = $passenger_name
          $_passenger_version = 'present'

          case $::osfamily {
            'RedHat' : { ensure_packages('mod_passenger') }
            'Debian' : { ensure_packages('libapache2-mod-passenger') }
            default  : { fail('Not Supported') }
          }
        }
        '4' : {
          case $::osfamily {
            'RedHat' : {

              # We dont support passenger 4 on centos 7
              if $::operatingsystemmajrelease == '7' {
                fail('Passenger version 4 is not supported on Centos7, Please setup using gems or select Passenger version 5')
              }

              $_passenger_name    = 'rubygem-passenger'
              $_passenger_version = 'present'

              # Install passenger apache module
              ensure_packages('rubygem-passenger-apache2-module')
            }
            'Debian' : {

              # TODO
              fail('Passenger version 4 is not supported on Debian family as of now')
            }
            default  : { fail('Not Supported') }
          }
        }
      }
      # get mod_passenger location for package installation
      $_passenger_mod_passenger = $passenger::params::mod_passenger
    }
    'gem' : {

      # Present should point to 5.0.20, casue we need version number to build proper passenger.conf for apache or nginx
      case $passenger_version {
        '5' : {
          $_passenger_version = '5.0.20'
        }
        '4' : {
          $_passenger_version = '4.0.59'
        }
        default  : { fail('Not Supported') }
      }

      # Variables need for gem installation
      $_passenger_name          = $passenger_name
      $_passenger_provider      = $passenger_provider

      # Setup default variables for gem installation
      class { '::passenger::gems' :
        passenger_version => $_passenger_version,
        notify            => Class['passenger::install']
      }

      # Get mod_passenger location for gems from passenger::gems
      $_passenger_mod_passenger = $passenger::gems::mod_passenger
    }
    default : {
      fail("${passenger_provider} is not support, Please contact administrator")
    }
  }

  # Install passenger standalone
  class { 'passenger::install' :
    passenger_name     => $_passenger_name,
    passenger_version  => $_passenger_version,
    passenger_provider => $_passenger_provider
  }

  if $passenger_version == '5' or $_passenger_provider == 'gem' {
    # Setup passenger with apache or nginx
    class { 'passenger::compile' :
      webserver     => $compile,
      mod_passenger => $_passenger_mod_passenger,
      require       => Class['passenger::install'],
      notify        => Class['passenger::config']
    }
  }

  # Setup the passenger.module file
  class { 'passenger::config' :
    manage_web_server => $manage_web_server,
    require           => Class['passenger::install' ]
  }

  if $manage_web_server {
    # Setup the webserver
    class { 'passenger::service' :
      webserver => $compile,
      require   => Class['passenger::install', 'passenger::config']
    }
  }
}
