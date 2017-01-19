# Class: nubis_alertmanager
# ===========================
#
# Full description of class nubis_alertmanager here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'nubis_alertmanager':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2017 Your name here, unless otherwise noted.
#
class nubis_alertmanager($version = '0.5.1', $project=undef) {
  $alertmanager_url = "https://github.com/prometheus/alertmanager/releases/download/v${version}/alertmanager-${version}.linux-amd64.tar.gz"

  if (!$project) {
    $project = $::project_name
  }

  notice ("Grabbing alertmanager ${version}")
  staging::file { "alertmanager.${version}.tar.gz":
    source => $alertmanager_url,
  }->
  staging::extract { "alertmanager.${version}.tar.gz":
    strip   => 1,
    target  => '/usr/local/bin',
    creates => '/usr/local/bin/alertmanager',
  }

  include 'upstart'

  upstart::job { 'alertmanager':
    description    => 'Prometheus Alert Manager',
    service_ensure => 'stopped',
    # Never give up
    respawn        => true,
    respawn_limit  => 'unlimited',
    start_on       => '(local-filesystems and net-device-up IFACE!=lo)',
    env            => {
      'SLEEP_TIME' => 1,
      'GOMAXPROCS' => 2,
    },
    user           => 'root',
    group          => 'root',
    script         => '
  if [ -r /etc/profile.d/proxy.sh ]; then
    echo "Loading Proxy settings"
    . /etc/profile.d/proxy.sh
  fi

  exec /usr/local/bin/alertmanager -config.file /etc/prometheus/alertmanager.yml -web.external-url "http://mon.$(nubis-metadata NUBIS_ENVIRONMENT).$(nubis-region).$(nubis-metadata NUBIS_ACCOUNT).$(nubis-metadata NUBIS_DOMAIN)/alertmanager"
',
    post_stop      => '
goal=$(initctl status $UPSTART_JOB | awk \'{print $2}\' | cut -d \'/\' -f 1)
if [ $goal != "stop" ]; then
    echo "Backoff for $SLEEP_TIME seconds"
    sleep $SLEEP_TIME
    NEW_SLEEP_TIME=`expr 2 \* $SLEEP_TIME`
    if [ $NEW_SLEEP_TIME -ge 60 ]; then
        NEW_SLEEP_TIME=60
    fi
    initctl set-env SLEEP_TIME=$NEW_SLEEP_TIME
fi
',
  }
}
