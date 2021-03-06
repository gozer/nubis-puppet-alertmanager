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
class nubis_alertmanager($version = '0.8.0', $tag_name='monitoring', $project=undef) {
  $alertmanager_url = "https://github.com/prometheus/alertmanager/releases/download/v${version}/alertmanager-${version}.linux-amd64.tar.gz"

  if ($project) {
    $alertmanager_project = $project
  }
  else {
    $alertmanager_project = $::project_name
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

  systemd::unit_file { 'alertmanager.service':
    source => "puppet:///modules/${module_name}/alertmanager.systemd",
  }
  ->service { 'alertmanager':
    enable => true,
  }

  file { '/etc/consul/svc-alertmanager.json':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${module_name}/svc-alertmanager.json.tmpl"),
  }

  file { '/etc/confd/conf.d/alertmanager.toml':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${module_name}/alertmanager.toml.tmpl"),
  }

  file { '/etc/confd/templates/alertmanager.yml.tmpl':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${module_name}/alertmanager.yml.tmpl.tmpl"),
  }
}
