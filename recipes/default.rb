#
# Cookbook:: spinnaker
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.


include_recipe 'spinnaker::install_packages'


# /app should be owned by root
directory node['spinnaker']['root']['folder'] do
  owner 'root'
  group 'root'
  mode '0755'
end

# create group run Halyard 
group node['spinnaker']['halyard']['group']['name'] do
  gid node['spinnaker']['halyard']['group']['id']
  system true
  action :create
end

# create spinnaker group 
group node['spinnaker']['halyard']['spinnaker']['group']['name'] do
  gid node['spinnaker']['halyard']['spinnaker']['group']['id']
  system true
  action :create
end

# create user Please supply a non-root user to run Halyard 

user node['spinnaker']['halyard']['user']['name'] do
  manage_home true
  comment 'HAL user account'
  uid node['spinnaker']['halyard']['user']['id']
  gid node['spinnaker']['halyard']['group']['id']
  home node['spinnaker']['halyard']['user']['home']
  shell '/bin/bash'
  system true
  action :create 
end


# create user Please supply a non-root user to run Halyard 

user node['spinnaker']['halyard']['spinnaker']['user']['name'] do
  manage_home true
  comment 'spinnaker user account'
  uid node['spinnaker']['halyard']['spinnaker']['user']['id']
  gid node['spinnaker']['halyard']['spinnaker']['group']['id']
  home node['spinnaker']['spinnaker ']['user']['home']
  shell '/bin/bash'
  system true
  action :create 
end

# create halyard group 
group node['spinnaker']['halyard']['halyard']['group']['name'] do
  system true
  action :create
  members node['spinnaker']['halyard']['user']['name']
end

# Halyard dirs
directory node['spinnaker']['halyard']['halconfig_dir'] do
  owner node['spinnaker']['halyard']['user']['name']
  group node['spinnaker']['halyard']['group']['name']
  mode '0755'
end

#local directories
default_directory = ::File.join(node['spinnaker']['halyard']['halconfig_dir'], 'default') 
profiles_directory = ::File.join(default_directory, 'profiles')
service_settings_directory = ::File.join(default_directory, 'service-settings')


dir_list = [default_directory, profiles_directory, service_settings_directory]
dir_list.each do |i|
  directory ::File.join("#{i}")do
      owner node['spinnaker']['halyard']['user']['name']
      group node['spinnaker']['halyard']['group']['name']
      mode '0755'
    end
end    

# halyard core
directory node['spinnaker']['halyard']['core']['halyard'] do
    owner node['spinnaker']['halyard']['user']['name']
    group node['spinnaker']['halyard']['halyard']['group']['name']
    mode '0755'
  end

# Spinnaker dir
spinnaker_dirs = [node['spinnaker']['halyard']['core']['spinnaker'], node['spinnaker']['halyard']['core']['spinconf_dir']]
spinnaker_dirs.each do |path|
	directory path do
		owner node['spinnaker']['halyard']['user']['name']
  		group node['spinnaker']['halyard']['spinnaker']['group']['name']
	  	mode '0755'
	end
end

# Spinnaker logs
spinnaker_logs = [node['spinnaker']['halyard']['spinnaker_logs'], node['spinnaker']['halyard']['halyard_logs']]
spinnaker_logs.each do |path|
	directory path do
		owner node['spinnaker']['halyard']['user']['name']
  		group node['spinnaker']['halyard']['spinnaker']['group']['name']
	  	mode '0755'
	end
end

# Adding HAL_USER
template ::File.join(node['spinnaker']['halyard']['core']['spinconf_dir'], 'halyard-user') do
  source 'halyard-user.erb'
  variables(
    'halyard_user' => node['spinnaker']['halyard']['user']['name']  
  )
  owner node['spinnaker']['halyard']['user']['name']
  group node['spinnaker']['halyard']['group']['name']
  mode '0755'
end
 
 # uninstall.sh
template ::File.join(node['spinnaker']['halyard']['halconfig_dir'], 'uninstall.sh') do
  source 'uninstall.sh.erb'
  variables(
  	'halconfig_dir' => node['spinnaker']['halyard']['halconfig_dir']  
  )
  owner 'root'
  mode '0755'
end

#halyard.yml
template ::File.join(node['spinnaker']['halyard']['core']['spinconf_dir'], 'halyard.yml') do
  source 'halyard.yml.erb'
  variables(
    'halconfig_dir' => node['spinnaker']['halyard']['halconfig_dir'],
    'spinnaker_repository_url' => node['spinnaker']['halyard']['spinnaker_repository_url'],
    'spinnaker_docker_registry' => node['spinnaker']['halyard']['spinnaker_docker_registry'],
    'spinnaker_gce_project' => node['spinnaker']['halyard']['spinnaker_gce_project'],
    'config_bucket' => node['spinnaker']['halyard']['config_bucket']
  )
  owner node['spinnaker']['halyard']['user']['name']
  group node['spinnaker']['halyard']['group']['name']
  mode '0755'
end

#front50-local.yml
template ::File.join(profiles_directory, 'front50-local.yml') do
  source 'front50-local.yml.erb'
  variables(
    's3_versioning' => node['spinnaker']['s3']['bucket']['versioning_enable']  
  )
  owner node['spinnaker']['halyard']['user']['name']
  mode '0755'
end

#gate.yml
template ::File.join(service_settings_directory, 'gate.yml') do
  source 'gate.yml.erb'
  variables(
    'host_ip' => node['spinnaker']['un_secured_host_ip']  
  )
  owner node['spinnaker']['halyard']['user']['name']
  mode '0755'
end

#deck.yml
template ::File.join(service_settings_directory, 'deck.yml') do
  source 'deck.yml.erb'
  variables(
    'host_ip' => node['spinnaker']['un_secured_host_ip']  
  )
  owner node['spinnaker']['halyard']['user']['name']
  mode '0755'
end

#config
template ::File.join(node['spinnaker']['halyard']['halconfig_dir'], 'config') do
  source 'config.erb'
  variables(
    'spin_version' => node['spinnaker']['halyard']['spinnaker_version'],
    's3_bucket_name' => node['spinnaker']['s3']['bucket']['name'],
    'root_folder' => node['spinnaker']['s3']['bucket']['root_floder'],
    'region' => node['spinnaker']['s3']['bucket']['region'],
    'aws_access_key' => node['spinnaker']['aws']['access_key'],
    'aws_secret_key' => node['spinnaker']['aws']['secret_access'],
    'overrideBaseUrl' => "http://#{node['spinnaker']['override_base_url']}"
  )
  owner node['spinnaker']['halyard']['user']['name']
  mode '0755'
end

#Hal Installation and configuration
tmp = Chef::Config[:file_cache_path]

tar_url = "#{node['spinnaker']['halyard']['jar_url']}/#{node['spinnaker']['halyard']['halyard_track']}/debian/halyard.tar.gz"

unless File.exist?("#{node['spinnaker']['halyard']['core']['halyard']}/bin/halyard")
  remote_file "#{tmp}/halyard.tar.gz" do
    mode '0644'
    source tar_url
  end
  
  package 'tar' 
  
  if node['spinnaker']['halyard']['core']['folder']
    execute "tar -xvf #{tmp}/halyard.tar.gz" do
      cwd node['spinnaker']['halyard']['core']['folder']
      user 'root'
      # user node['spinnaker']['halyard']['user']['name']
      # group node['spinnaker']['halyard']['halyard']['group']['name']
      end  
     execute 'ownership' do
        command "chown -R #{node['spinnaker']['halyard']['user']['name']}:#{node['spinnaker']['halyard']['halyard']['group']['name']} #{node['spinnaker']['halyard']['core']['halyard']}"
        action :run
      end   
  end
end

# move hal start scripts
bash 'move hal start scripts' do
  cwd '/opt'
  code <<-EOH
  mv /opt/hal /usr/local/bin
  chmod a+rx /usr/local/bin/hal
  mv /opt/update-halyard /usr/local/bin
  chmod a+rx /usr/local/bin/update-halyard
  EOH
end

#Staring the Hal
execute 'Starting HAL' do
  command 'hal -v'
  action :run
  user node['spinnaker']['halyard']['user']['name']
  live_stream true
end

#spinnaker deploy
 # spinnaker deploy : This is the critical step in spinnaker setup.
 #      This setp will download the required binaries and dependencies
 #      from internet and install.
 #      Its completly managed by halyard service.  
bash 'spinnaker deploy' do
  code <<-EOH
  hal deploy apply
  EOH
end

#spinnaker connect 
"""
  spinnaker connect: will enable the connectivity between deck and gate api.

"""
bash 'spinnaker connect' do
  code <<-EOH
  hal deploy connect
  EOH
end


#spinnaker stop, updating the ownership and start the services
unless ::File.join(node['spinnaker']['halyard']['core']['halyard'], 'pid')

  execute 'restarting deamon' do
    command 'systemctl daemon-reload'
    action :run
  end 

  service_list = ["apache2", "redis-server", "spinnaker"]
    service_list.each do |service_name|
        service service_name do
          action [:restart]
        end
  end  

  # spin_dir_list = ["clouddriver", "echo", "front50", "gate", "igor", "orca", "rosco", "spinnaker-monitoring"]  
  # spin_dir_list.each do |item|
  #   execute 'ownership' do
  #       command "chown -R #{node['spinnaker']['halyard']['user']['name']}:#{node['spinnaker']['halyard']['halyard']['group']['name']} #{item} }"
  #       action :run
  #     end
  # end

  # service_list = ["apache2", "redis-server", "spinnaker"]
  #   service_list.each do |service_name|
  #       service service_name do
  #         action [:start]
  #       end
  # end
    
end
