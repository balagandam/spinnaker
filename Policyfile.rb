# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'spinnaker'

# Where to find external cookbooks:
default_source :supermarket

#java thirdparty
cookbook 'java', '~> 4.2.0', :supermarket
cookbook 'minio-server', '~> 0.1.1', :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'spinnaker::default'

# Specify a custom source for a single cookbook:
cookbook 'spinnaker', path: '.'
