#!/usr/bin/env bash

## auto-generated debian install file written by halyard

set -e
set -o pipefail

# install redis as a local service
INSTALL_REDIS="true"

# install first-time spinnaker dependencies (java, setup apt repos)
PREPARE_ENVIRONMENT="true"

REPOSITORY_URL="https://dl.bintray.com/spinnaker-releases/debians"

echo_err() {
  echo "$@" 1>&2
}

## check that the user is root
if [[ `/usr/bin/id -u` -ne 0 ]]; then
  echo_err "$0 must be executed with root permissions; exiting"
  exit 1
fi

if [[ -f /etc/lsb-release ]]; then
  . /etc/lsb-release
  DISTRO=$DISTRIB_ID
elif [[ -f /etc/debian_version ]]; then
  DISTRO=Debian
  # XXX or Ubuntu
elif [[ -f /etc/redhat-release ]]; then
  if grep -iq cent /etc/redhat-release; then
    DISTRO="CentOS"
  elif grep -iq red /etc/redhat-release; then
    DISTRO="RedHat"
  fi
else
  DISTRO=$(uname -s)
fi

# If not Ubuntu 14.xx.x or higher

if [ "$DISTRO" = "Ubuntu" ]; then
  if [ "${DISTRIB_RELEASE%%.*}" -lt "14" ]; then
    echo_err "Not a supported version of Ubuntu"
    echo_err "Version is $DISTRIB_RELEASE we require 14.04"
    exit 1
  fi
else
  echo_err "Not a supported operating system: " $DISTRO
  echo_err "It's recommended you use Ubuntu 14.04 or greater."
  echo_err ""
  echo_err "Please file an issue against https://github.com/spinnaker/spinnaker/issues"
  echo_err "if you'd like to see support for your OS and version"
  exit 1
fi

function add_redis_apt_repository() {
  add-apt-repository -y ppa:chris-lea/redis-server
}

function add_spinnaker_apt_repository() {
  REPOSITORY_HOST=$(echo $REPOSITORY_URL | cut -d/ -f3)
  if [[ "$REPOSITORY_HOST" == "dl.bintray.com" ]]; then
    REPOSITORY_ORG=$(echo $REPOSITORY_URL | cut -d/ -f4)
    # Personal repositories might not be signed, so conditionally check.
    gpg=""
    gpg=$(curl -s -f "https://bintray.com/user/downloadSubjectPublicKey?username=$REPOSITORY_ORG") || true
    if [[ ! -z "$gpg" ]]; then
      echo "$gpg" | apt-key add -
    fi
  fi
  echo "deb $REPOSITORY_URL $DISTRIB_CODENAME spinnaker" | tee /etc/apt/sources.list.d/spinnaker.list > /dev/null
}

function add_java_apt_repository() {
  add-apt-repository -y ppa:openjdk-r/ppa
}

function install_java() {
  set +e
  local java_version=$(java -version 2>&1 head -1)
  set -e

  if [[ "$java_version" == *1.8* ]]; then
    echo "Java is already installed & at the right version"
    return 0;
  fi

  apt-get install -y --force-yes unzip
  apt-get install -y --force-yes openjdk-8-jdk

  # https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/983302
  # It seems a circular dependency was introduced on 2016-04-22 with an openjdk-8 release, where
  # the JRE relies on the ca-certificates-java package, which itself relies on the JRE.
  # This causes the /etc/ssl/certs/java/cacerts file to never be generated, causing a startup
  # failure in Clouddriver.
  dpkg --purge --force-depends ca-certificates-java
  apt-get install ca-certificates-java
}

echo "Updating apt package lists..."

if [ -n "$INSTALL_REDIS" ]; then
  add_redis_apt_repository
fi

if [ -n "$PREPARE_ENVIRONMENT" ]; then
  add_java_apt_repository
  add_spinnaker_apt_repository
  source /etc/os-release

if [ "$VERSION_ID" = "14.04" ]; then
  cat > /etc/init/spinnaker.conf <<EOL
description "spinnaker"
start on filesystem or runlevel [2345]
stop on shutdown
pre-start script
  for i in clouddriver echo front50 gate igor orca rosco
  do
    if [ ! -d "/var/log/spinnaker/\$i" ]; then
      echo "/var/log/spinnaker/\$i does not exist. Creating it..."
      install --mode=755 --owner=spinnaker --group=spinnaker --directory /var/log/spinnaker/\$i
    fi
    service \$i start
  done
end script
EOL
else
  cat > /lib/systemd/system/spinnaker.service <<EOL
[Unit]
Description=All Spinnaker services
After=network.target
Wants=clouddriver.service echo.service front50.service gate.service igor.service orca.service rosco.service
[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOL
fi

fi

apt-get update ||:

echo "Installing desired components..."

if [ -n "$PREPARE_ENVIRONMENT" ]; then
  install_java
fi

if [ -z "$(getent group spinnaker)" ]; then
  groupadd spinnaker
fi

if [ -z "$(getent passwd spinnaker)" ]; then
  if [ "$homebase" = "" ]; then
    homebase="/home"
    echo "Setting spinnaker home to $homebase"
  fi

  useradd --gid spinnaker -m --home-dir $homebase/spinnaker spinnaker
fi

mkdir -p /opt/spinnaker/config
chown spinnaker /opt/spinnaker/config

mkdir -p /opt/spinnaker-monitoring/config
chown spinnaker /opt/spinnaker-monitoring/config

mkdir -p /opt/spinnaker-monitoring/registry
chown spinnaker /opt/spinnaker-monitoring/registry

cat > /etc/apt/preferences.d/pin-spin-igor <<EOL
Package: spinnaker-igor
Pin: version 1.4.0-20190709142816
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-igor=1.4.0-20190709142816

set +e
service igor stop
set -e
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
mkdir -p $(dirname /opt/spinnaker/config/igor.yml)
cp -p /app/deployer/.hal/default/staging/igor.yml /opt/spinnaker/config/igor.yml
chown spinnaker:spinnaker /opt/spinnaker/config/igor.yml
chmod 640 /opt/spinnaker/config/igor.yml
cat > /etc/apt/preferences.d/pin-spin-clouddriver <<EOL
Package: spinnaker-clouddriver
Pin: version 6.0.1-20190726051325
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-clouddriver=6.0.1-20190726051325

set +e
service clouddriver stop
set -e
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
mkdir -p $(dirname /opt/spinnaker/config/clouddriver.yml)
cp -p /app/deployer/.hal/default/staging/clouddriver.yml /opt/spinnaker/config/clouddriver.yml
chown spinnaker:spinnaker /opt/spinnaker/config/clouddriver.yml
chmod 640 /opt/spinnaker/config/clouddriver.yml
cat > /etc/apt/preferences.d/pin-spin-orca <<EOL
Package: spinnaker-orca
Pin: version 2.8.1-20190720051319
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-orca=2.8.1-20190720051319

set +e
service orca stop
set -e
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
mkdir -p $(dirname /opt/spinnaker/config/orca.yml)
cp -p /app/deployer/.hal/default/staging/orca.yml /opt/spinnaker/config/orca.yml
chown spinnaker:spinnaker /opt/spinnaker/config/orca.yml
chmod 640 /opt/spinnaker/config/orca.yml
cat > /etc/apt/preferences.d/pin-spin-deck <<EOL
Package: spinnaker-deck
Pin: version 2.10.1-20190726153309
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-deck=2.10.1-20190726153309



mkdir -p $(dirname /opt/deck/html/settings.js)
cp -p /app/deployer/.hal/default/staging/settings.js /opt/deck/html/settings.js
chown www-data:spinnaker /opt/deck/html/settings.js
chmod 640 /opt/deck/html/settings.js
mkdir -p $(dirname /etc/apache2/passphrase)
cp -p /app/deployer/.hal/default/staging/apache2/passphrase /etc/apache2/passphrase
chown www-data:spinnaker /etc/apache2/passphrase
chmod 640 /etc/apache2/passphrase
chmod +x /etc/apache2/passphrase
mkdir -p $(dirname /etc/apache2/ports.conf)
cp -p /app/deployer/.hal/default/staging/apache2/ports.conf /etc/apache2/ports.conf
chown www-data:spinnaker /etc/apache2/ports.conf
chmod 640 /etc/apache2/ports.conf
mkdir -p $(dirname /etc/apache2/sites-available/spinnaker.conf)
cp -p /app/deployer/.hal/default/staging/apache2/spinnaker.conf /etc/apache2/sites-available/spinnaker.conf
chown www-data:spinnaker /etc/apache2/sites-available/spinnaker.conf
chmod 640 /etc/apache2/sites-available/spinnaker.conf
a2ensite spinnaker
a2dissite 000-default
cat > /etc/apt/preferences.d/pin-spin-front50 <<EOL
Package: spinnaker-front50
Pin: version 0.18.0-20190709142816
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-front50=0.18.0-20190709142816

set +e
service front50 stop
set -e
mkdir -p $(dirname /home/spinnaker/.aws/credentials)
cp -p /app/deployer/.hal/default/staging/aws/front50-credentials_home_spinnaker /home/spinnaker/.aws/credentials
chown spinnaker:spinnaker /home/spinnaker/.aws/credentials
chmod 640 /home/spinnaker/.aws/credentials
mkdir -p $(dirname /opt/spinnaker/config/front50-local.yml)
cp -p /app/deployer/.hal/default/staging/front50-local.yml /opt/spinnaker/config/front50-local.yml
chown spinnaker:spinnaker /opt/spinnaker/config/front50-local.yml
chmod 640 /opt/spinnaker/config/front50-local.yml
mkdir -p $(dirname /opt/spinnaker/config/front50.yml)
cp -p /app/deployer/.hal/default/staging/front50.yml /opt/spinnaker/config/front50.yml
chown spinnaker:spinnaker /opt/spinnaker/config/front50.yml
chmod 640 /opt/spinnaker/config/front50.yml
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
cat > /etc/apt/preferences.d/pin-spin-rosco <<EOL
Package: spinnaker-rosco
Pin: version 0.13.0-20190709142816
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-rosco=0.13.0-20190709142816

set +e
service rosco stop
set -e
mkdir -p $(dirname /opt/rosco/config/packer/aws-ebs.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/aws-ebs.json /opt/rosco/config/packer/aws-ebs.json
chown spinnaker:spinnaker /opt/rosco/config/packer/aws-ebs.json
chmod 640 /opt/rosco/config/packer/aws-ebs.json
mkdir -p $(dirname /opt/spinnaker/config/rosco.yml)
cp -p /app/deployer/.hal/default/staging/rosco.yml /opt/spinnaker/config/rosco.yml
chown spinnaker:spinnaker /opt/spinnaker/config/rosco.yml
chmod 640 /opt/spinnaker/config/rosco.yml
mkdir -p $(dirname /opt/rosco/config/packer/aws-chroot.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/aws-chroot.json /opt/rosco/config/packer/aws-chroot.json
chown spinnaker:spinnaker /opt/rosco/config/packer/aws-chroot.json
chmod 640 /opt/rosco/config/packer/aws-chroot.json
mkdir -p $(dirname /opt/rosco/config/packer/scripts/windows-install-packages.ps1)
cp -p /app/deployer/.hal/default/staging/rosco/packer/scripts/windows-install-packages.ps1 /opt/rosco/config/packer/scripts/windows-install-packages.ps1
chown spinnaker:spinnaker /opt/rosco/config/packer/scripts/windows-install-packages.ps1
chmod 640 /opt/rosco/config/packer/scripts/windows-install-packages.ps1
mkdir -p $(dirname /opt/rosco/config/packer/azure-windows-2012-r2.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/azure-windows-2012-r2.json /opt/rosco/config/packer/azure-windows-2012-r2.json
chown spinnaker:spinnaker /opt/rosco/config/packer/azure-windows-2012-r2.json
chmod 640 /opt/rosco/config/packer/azure-windows-2012-r2.json
mkdir -p $(dirname /opt/rosco/config/packer/scripts/aws-windows-2012-configure-ec2service.ps1)
cp -p /app/deployer/.hal/default/staging/rosco/packer/scripts/aws-windows-2012-configure-ec2service.ps1 /opt/rosco/config/packer/scripts/aws-windows-2012-configure-ec2service.ps1
chown spinnaker:spinnaker /opt/rosco/config/packer/scripts/aws-windows-2012-configure-ec2service.ps1
chmod 640 /opt/rosco/config/packer/scripts/aws-windows-2012-configure-ec2service.ps1
mkdir -p $(dirname /opt/rosco/config/packer/oci.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/oci.json /opt/rosco/config/packer/oci.json
chown spinnaker:spinnaker /opt/rosco/config/packer/oci.json
chmod 640 /opt/rosco/config/packer/oci.json
mkdir -p $(dirname /opt/rosco/config/packer/azure-linux.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/azure-linux.json /opt/rosco/config/packer/azure-linux.json
chown spinnaker:spinnaker /opt/rosco/config/packer/azure-linux.json
chmod 640 /opt/rosco/config/packer/azure-linux.json
mkdir -p $(dirname /opt/rosco/config/packer/aws-windows-2012-r2.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/aws-windows-2012-r2.json /opt/rosco/config/packer/aws-windows-2012-r2.json
chown spinnaker:spinnaker /opt/rosco/config/packer/aws-windows-2012-r2.json
chmod 640 /opt/rosco/config/packer/aws-windows-2012-r2.json
mkdir -p $(dirname /opt/rosco/config/packer/scripts/windows-configure-chocolatey.ps1)
cp -p /app/deployer/.hal/default/staging/rosco/packer/scripts/windows-configure-chocolatey.ps1 /opt/rosco/config/packer/scripts/windows-configure-chocolatey.ps1
chown spinnaker:spinnaker /opt/rosco/config/packer/scripts/windows-configure-chocolatey.ps1
chmod 640 /opt/rosco/config/packer/scripts/windows-configure-chocolatey.ps1
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
mkdir -p $(dirname /opt/rosco/config/packer/aws-multi-chroot.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/aws-multi-chroot.json /opt/rosco/config/packer/aws-multi-chroot.json
chown spinnaker:spinnaker /opt/rosco/config/packer/aws-multi-chroot.json
chmod 640 /opt/rosco/config/packer/aws-multi-chroot.json
mkdir -p $(dirname /opt/rosco/config/packer/scripts/aws-windows.userdata)
cp -p /app/deployer/.hal/default/staging/rosco/packer/scripts/aws-windows.userdata /opt/rosco/config/packer/scripts/aws-windows.userdata
chown spinnaker:spinnaker /opt/rosco/config/packer/scripts/aws-windows.userdata
chmod 640 /opt/rosco/config/packer/scripts/aws-windows.userdata
mkdir -p $(dirname /opt/rosco/config/packer/docker.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/docker.json /opt/rosco/config/packer/docker.json
chown spinnaker:spinnaker /opt/rosco/config/packer/docker.json
chmod 640 /opt/rosco/config/packer/docker.json
mkdir -p $(dirname /opt/rosco/config/packer/install_packages.sh)
cp -p /app/deployer/.hal/default/staging/rosco/packer/install_packages.sh /opt/rosco/config/packer/install_packages.sh
chown spinnaker:spinnaker /opt/rosco/config/packer/install_packages.sh
chmod 640 /opt/rosco/config/packer/install_packages.sh
chmod +x /opt/rosco/config/packer/install_packages.sh
mkdir -p $(dirname /opt/rosco/config/packer/aws-multi-ebs.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/aws-multi-ebs.json /opt/rosco/config/packer/aws-multi-ebs.json
chown spinnaker:spinnaker /opt/rosco/config/packer/aws-multi-ebs.json
chmod 640 /opt/rosco/config/packer/aws-multi-ebs.json
mkdir -p $(dirname /opt/rosco/config/packer/gce.json)
cp -p /app/deployer/.hal/default/staging/rosco/packer/gce.json /opt/rosco/config/packer/gce.json
chown spinnaker:spinnaker /opt/rosco/config/packer/gce.json
chmod 640 /opt/rosco/config/packer/gce.json
cat > /etc/apt/preferences.d/pin-spin-echo <<EOL
Package: spinnaker-echo
Pin: version 2.6.0-20190709142816
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-echo=2.6.0-20190709142816

set +e
service echo stop
set -e
mkdir -p $(dirname /opt/spinnaker/config/echo.yml)
cp -p /app/deployer/.hal/default/staging/echo.yml /opt/spinnaker/config/echo.yml
chown spinnaker:spinnaker /opt/spinnaker/config/echo.yml
chmod 640 /opt/spinnaker/config/echo.yml
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
cat > /etc/apt/preferences.d/pin-spin-gate <<EOL
Package: spinnaker-gate
Pin: version 1.9.0-20190719051321
Pin-Priority: 1001
EOL

apt-get install -y --force-yes --allow-unauthenticated spinnaker-gate=1.9.0-20190719051321

set +e
service gate stop
set -e
mkdir -p $(dirname /opt/spinnaker/config/spinnaker.yml)
cp -p /app/deployer/.hal/default/staging/spinnaker.yml /opt/spinnaker/config/spinnaker.yml
chown spinnaker:spinnaker /opt/spinnaker/config/spinnaker.yml
chmod 640 /opt/spinnaker/config/spinnaker.yml
mkdir -p $(dirname /opt/spinnaker/config/gate.yml)
cp -p /app/deployer/.hal/default/staging/gate.yml /opt/spinnaker/config/gate.yml
chown spinnaker:spinnaker /opt/spinnaker/config/gate.yml
chmod 640 /opt/spinnaker/config/gate.yml
apt-get -q -y --force-yes install redis-server && (systemctl start redis-server.service || true)


# so this script can be used for updates
set +e
service spinnaker restart

# Ensure apache is started for deck. Restart to ensure enabled site is loaded.
service apache2 restart
