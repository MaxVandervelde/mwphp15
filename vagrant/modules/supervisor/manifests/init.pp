# Class: supervisor
#
# Usage:
#   include supervisor
#
#   class { 'supervisor':
#     include_superlance      => false,
#     enable_http_inet_server => true,
#   }
#
#
# TODO: configurations pass as parameters
class supervisor (
  $include_superlance       = true,
  $enable_http_inet_server  = true,
) {

  # TODO: support debian installations
  case $::osfamily {
    redhat: {
      $pkg_setuptools = 'python-setuptools'
      $init_script = 'puppet:///modules/supervisor/redhat.supervisord'
    }
    debian: {
      $pkg_setuptools = 'python-setupdocs'
      $init_script = 'puppet:///modules/supervisor/debian.supervisord'
    }
    default: { fail("ERROR: ${::osfamily} based systems are not supported!") }
  }

  package { $pkg_setuptools: ensure => installed, }

  # let's stick with v3.0 for now
  exec { 'easy_install-supervisor':
    command => '/usr/bin/easy_install supervisor==3.0',
    creates => '/usr/bin/supervisord',
    user    => 'root',
    require => Package[$pkg_setuptools],
  }

  # install start/stop script
  file { '/etc/init.d/supervisord':
    source => $init_script,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/var/log/supervisor':
    ensure  => directory,
    purge   => true,
    backup => false,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    require => Exec['easy_install-supervisor'],
  }

  file { '/etc/supervisord.conf':
    ensure  => file,
    content => template('supervisor/supervisord.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['easy_install-supervisor'],
    notify  => Service['supervisord'],
  }

  file { '/etc/supervisord.d':
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode => '0755',
    require => File['/etc/supervisord.conf'],
  }

  service { 'supervisord':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/supervisord.conf'],
  }

  if $include_superlance {
    exec { 'easy_install-superlance':
      command => '/usr/bin/easy_install superlance',
      creates => '/usr/bin/memmon',
      user    => 'root',
      require => Exec['easy_install-supervisor'],
    }
  }

}
