
#
# Cookbook:: spinnaker
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.



#add_apt_repositories_module
bash 'add_apt_repositories_module' do
  code <<-EOH
  # Java 8
  # https://launchpad.net/~openjdk-r/+archive/ubuntu/ppa
  apt-get install -y software-properties-common
  add-apt-repository -y ppa:openjdk-r/ppa
  apt-get update ||:
    EOH
  not_if { ::File.exist?("#{node['spinnaker']['halyard']['openjdk_repo_file']}")}
end

#openjdk
package 'openjdk-8-jdk' do
  action :install
end

# dpkg_package 'ca-certificates-java' do
#   action :purge
# end
# 
#purge ca-certificates-java
execute "purge java" do
    command "dpkg --purge --force-depends ca-certificates-java"
end

apt_update

#instal ca-certificates-java
package 'ca-certificates-java' do
  action :install
end

#Apache2
package 'apache2' do
  action :install
end

service 'apache2' do
  action [:enable, :start]
end

#redis server
package 'redis-server' do
  action :install
end

package 'redis-tools' do
  action :install
end

service 'redis-server' do
  action [:enable, :start]
end
