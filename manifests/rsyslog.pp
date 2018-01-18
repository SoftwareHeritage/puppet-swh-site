# Parameters for rsyslog
class profile::rsyslog {

    file_line {'rsyslog maxsize':
	path    => '/etc/logrotate.d/rsyslog',
	line    => '	maxsize 100M',
	after => 'weekly',
    }

}
