class phalconvm::varnish (
	$enabled      = false,
	$port         = '6081',
	$storage_size = '64m',
	$ttl          = '120',
) {
	if $enabled == true {
		package { 'varnish':
			ensure => 'installed',
		}

		service { 'varnish':
			ensure  => 'running',
			require => Package['varnish'],
		}

		exec { 'varnish-service-file':
			command => '/bin/cp /lib/systemd/system/varnish.service /etc/systemd/system/',
			creates => '/etc/systemd/system/varnish.service',
			require => Package['varnish'],
		}

		$varnish_service = {
			'Service' => {
				'ExecStart' => "/usr/sbin/varnishd -j unix,user=vcache -F -a :${port} -T localhost:6082 -f /etc/varnish/default.vcl -t ${ttl} -S /etc/varnish/secret -s malloc,${storage_size}",
			},
		}

		create_ini_settings( $varnish_service, {
			path    => '/etc/systemd/system/varnish.service',
			require => Exec['varnish-service-file'],
			notify  => Service['varnish'],
		} )

		file { '/etc/varnish/default.vcl':
			ensure  => 'present',
			content => template( 'phalconvm/varnish/default.vcl.erb' ),
			require => Package['varnish'],
			notify  => Service['varnish'],
		}
	} else {
		service { 'varnish':
			ensure => 'stopped',
		}

		exec { 'varnish-unmount':
			command => 'umount /var/lib/varnish',
			path    => '/bin:/usr/bin',
			unless  => "test -n `mount | grep varnish`",
		}

		package { 'varnish':
			ensure  => 'purged',
			require => [ Service['varnish'], Exec['varnish-unmount'] ],
		}

		exec { 'varnish-remove':
			command     => 'apt-get autoremove --purge -y',
			refreshonly => true,
			path        => '/bin:/usr/bin',
			subscribe   => Package['varnish'],
		}
	}
}
