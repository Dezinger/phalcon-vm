class phalconvm::postgres(
	$enabled  = true,
    $password = 'postgres',
) {
	if $enabled == true {
		class { 'postgresql::server':
			postgres_password => $password,
		}
	} else {
		service { 'postgresql':
			ensure => 'stopped',
		}

		package { ['postgresql-9.5', 'postgresql-client-9.5']:
			ensure  => 'purged',
			require => Service['postgresql'],
		}

		exec { 'postgresql-remove':
			command     => '/usr/bin/apt-get autoremove --purge -y',
			refreshonly => true,
			subscribe   => Package['postgresql-9.5'],
		}
	}
}
