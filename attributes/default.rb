
# <> Spinnaker HAL user's name. Please supply a non-root user to run Halyard 
default['spinnaker']['halyard']['user']['name'] = 'deployer'
# <> Spinnaker user id
default['spinnaker']['halyard']['user']['id'] = 1500
# <> Halyard runner group's name.
default['spinnaker']['halyard']['group']['name'] = 'deployer'
# <> Spinnaker gropu id
default['spinnaker']['halyard']['group']['id'] = 1500
# <> Spinnaker runner group's name.
default['spinnaker']['halyard']['spinnaker']['group']['name'] = 'spinnaker'
default['spinnaker']['halyard']['spinnaker']['group']['id'] = 1600
default['spinnaker']['halyard']['spinnaker']['user']['name'] = 'spinnaker'
default['spinnaker']['halyard']['spinnaker']['user']['id'] = 1600
# <> halyard runner group's name.
default['spinnaker']['halyard']['halyard']['group']['name'] = 'halyard'
# # <> Spinnaker user shell
# default['spinnaker']['halyard']['user']['shell'] = '/bin/bash'


# <> Repos and registries 

# # <> halyard  base url
# default['spinnaker']['halyard']['repository_url'] = "https://dl.bintray.com/spinnaker-releases/debians"
# <> spinnaker repository
default['spinnaker']['halyard']['spinnaker_repository_url'] = "https://dl.bintray.com/spinnaker-releases/debians"
# # <> spinnaker registry
# default['spinnaker']['halyard']['spinnaker_registry'] = nil
# <> spinnaker docker registry
default['spinnaker']['halyard']['spinnaker_docker_registry'] = "gcr.io/spinnaker-marketplace"
# <> spinnaker gce project
default['spinnaker']['halyard']['spinnaker_gce_project'] = "marketplace-spinnaker-release"
# <> Halyard gcs config url
default['spinnaker']['halyard']['gcs_bucket_url'] = "/spinnaker-artifacts/halyard"
# <> Halyard config bucket
default['spinnaker']['halyard']['config_bucket'] = "halconfig"



# # <> spinnaker repo username
# default['spinnaker']['halyard']['spinnaker_publickey_username'] = "spinnaker-releases"
# # <> Halyard jar based installation url
default['spinnaker']['halyard']['jar_url'] = "https://storage.googleapis.com/spinnaker-artifacts/halyard"
# <> spinnaker repo track
default['spinnaker']['halyard']['halyard_track'] = 'stable'
#<> spinnaker repo file
# default['spinnaker']['halyard']['spinnaker_repo_file'] = "/etc/apt/sources.list.d/halyard.list"

#<> open jdk repo file
default['spinnaker']['halyard']['openjdk_repo_file'] = "/etc/apt/sources.list.d/openjdk-r-ppa-trusty.list"

# <> Package and version

default['spinnaker']['halyard']['spinnaker_version'] = '1.15.1'

# <> halyard config directories 

# # <> Halyard installation's root directory
default['spinnaker']['root']['folder'] = '/app'
# <> Halyard user home directory
default['spinnaker']['halyard']['user']['home'] = "#{node['spinnaker']['root']['folder']}/deployer"
# <> halyard config directory
default['spinnaker']['halyard']['halconfig_dir'] = "#{node['spinnaker']['halyard']['user']['home']}/.hal"
# <> spinnaker user home directory
default['spinnaker']['spinnaker ']['user']['home'] = "#{node['spinnaker']['root']['folder']}/spinnaker"

#spinnaker directories
#<> spinnaker core directory
default['spinnaker']['halyard']['core']['folder'] = '/opt'
# <> spinnaker directory
default['spinnaker']['halyard']['core']['halyard'] = "#{node['spinnaker']['halyard']['core']['folder']}/halyard"
# <> spinnaker directory
default['spinnaker']['halyard']['core']['spinnaker'] = "#{node['spinnaker']['halyard']['core']['folder']}/spinnaker"
# <> spinnaker config directory
default['spinnaker']['halyard']['core']['spinconf_dir'] = "#{node['spinnaker']['halyard']['core']['spinnaker']}/config"
# <> spinnaker halyard user config file
default['spinnaker']['halyard']['core']['halyard_user_config'] = "#{node['spinnaker']['halyard']['core']['spinconf_dir']}/halyard-user"


#logs
# <> spinnaker logs directory
default['spinnaker']['halyard']['spinnaker_logs'] = "/var/log/spinnaker"
# <> halyard logs directory
default['spinnaker']['halyard']['halyard_logs'] = "#{node['spinnaker']['halyard']['spinnaker_logs']}/halyard"

#S3
#
default['spinnaker']['s3']['bucket']['name'] = nil
#
default['spinnaker']['s3']['bucket']['root_floder'] = nil
#
default['spinnaker']['s3']['bucket']['region'] = nil
#
default['spinnaker']['s3']['bucket']['versioning_enable'] = false

#AWS
#AWS 
default['spinnaker']['aws']['s3_bucket_config']= false
#AWS access_key
default['spinnaker']['aws']['access_key'] = nil
#AWS secret_access
default['spinnaker']['aws']['secret_access'] = nil

#GCP
#GCP access_key
default['spinnaker']['gcp']['access_key'] = nil
#GCP secret_access
default['spinnaker']['gcp']['secret_access'] = nil

#spinnaker host override_base_url
default['spinnaker']['override_base_url'] = nil
default['spinnaker']['un_secured_host_ip'] =  nil



