# == Class: monit
#
# This module controls Monit
#
# === Parameters
#
# [*ensure*]   - If you want the service running or not
# [*admin*]    - Admin email address
# [*interval*] - How frequently the check runs
# [*logfile*]  - What file for monit use for logging
#
# === Examples
#
#  class { 'monit':
#    admin    => 'me@mydomain.local',
#    interval => 30,
#  }
#
# === Authors
#
# Eivind Uggedal <eivind@uggedal.com>
# Jonathan Thurman <jthurman@newrelic.com>
#
# === Copyright
#
# Copyright 2011 Eivind Uggedal <eivind@uggedal.com>
#
class monit (
  $ensure     = present,
  $admin      = undef,
  $mailserver = 'localhost',
  $mailformat = "from: monit_${::hostname}@${::domain}",
  $interval   = '60',
  $logfile    = $monit::params::logfile,
) inherits monit::params {

  $conf_include = "${monit::params::conf_dir}/*"

  if ($ensure == 'present') {
    $run_service = true
    $svc_ensure  = 'running'
  } else {
    $run_service = false
    $svc_ensure  = 'stopped'
  }

  package { $monit::params::monit_package:
    ensure => $ensure,
  }

  # Template uses: $admin, $conf_include, $interval, $logfile
  file { $monit::params::conf_file:
    ensure  => $ensure,
    content => template('monit/monitrc.erb'),
    mode    => '0600',
    require => Package[$monit::params::monit_package],
    notify  => Service[$monit::params::monit_service],
  }

  file { $monit::params::conf_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Not all platforms need this
  if ($monit::params::conf_default) {
    file { $monit::params::conf_default:
      ensure  => $ensure,
      content => "startup=1\n",
      require => Package[$monit::params::monit_package],
    }
  }

  # Template uses: $logfile
  file { $monit::params::logrotate_script:
    ensure  => $ensure,
    content => template("monit/${monit::params::logrotate_source}"),
    require => Package[$monit::params::monit_package],
  }

  service { $monit::params::monit_service:
    ensure     => $svc_ensure,
    enable     => $run_service,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File[$monit::params::conf_file],
    require    => [
      File[$monit::params::conf_file],
      File[$monit::params::logrotate_script]
    ],
  }
}
