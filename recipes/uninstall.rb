#
# Cookbook:: spinnaker
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

unless ::File.join(node['spinnaker']['halyard']['core']['halyard'], 'pid')
	
	serivce_list = ["apache2", "redis", "spinnaker"]
	serivce_list.each do |service_name|
		service service_name do
		  action [:stop]
		end	
	end

	execute 'uninstalling spinnaker' do
	  cwd node['spinnaker']['halyard']['halconfig_dir']
	  command 'sudo bash uninstall.sh'
	  action :run
	end  
	
end