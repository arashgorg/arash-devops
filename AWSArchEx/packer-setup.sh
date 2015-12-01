#!/bin/bash

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=us-west-2

# Install awscli, salt-master, salt-minion, and tools
echo 'Installing packages ...'
echo 'deb http://debian.saltstack.com/debian jessie-saltstack-2015-05 main' > /etc/apt/sources.list.d/saltstack.list
wget -q -O - 'http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key' | apt-key add -
echo 'deb http://packages.elasticsearch.org/logstashforwarder/debian stable main' > /etc/apt/sources.list.d/elasticsearch.list
wget -q -O - 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch' | apt-key add -
apt-get update
apt-get install -y curl dnsutils jq logstash-forwarder python-pip pv salt-master salt-minion sysstat tmux vim
pip install awscli

# Install node-exporter
mkdir -p /opt/node-exporter/bin
wget -q -O - https://github.com/prometheus/node_exporter/releases/download/0.11.0/node_exporter-0.11.0.linux-amd64.tar.gz | tar -C /opt/node-exporter/bin --no-same-owner -xzf -

# Install libgit2 and pygit2
# NB: libgit2 has to be built from sources because Debian Jessie ships 0.21 and we need 0.22
apt-get install -y cmake libssh2-1-dev libssl-dev pkg-config python-cffi python-dev
pushd /tmp
wget -q -O - https://github.com/libgit2/libgit2/archive/v0.22.0.tar.gz | tar xzf -
pushd libgit2-0.22.0
cmake .
make install
popd
rm -rf libgit2-0.22.0
popd
LDFLAGS="-Wl,-rpath='/usr/local/lib',--enable-new-dtags" pip install pygit2==0.22.0
python -c 'import pygit2'

# Stop the master and minion and cleanup any state they may have accrued
echo 'Stopping salt-master and salt-minion ...'
systemctl stop salt-master salt-minion
rm -f /etc/salt/minion_id /etc/salt/pki/minion/minion_master.pub

# Run the master in open mode (changed this)
echo 'Setting salt-master to run in open mode ...'
sed -e 's/#open_mode:.*/open_mode: True/' -i /etc/salt/master

# Auto-accept keys at the master
echo 'Setting salt-master to auto-accept keys ...'
sed -e 's/#auto_accept:.*/auto_accept: True/' -i /etc/salt/master

# Don't add the master's config data to pillars
echo 'Disabling salt-master data in pillars ...'
sed -e 's/#pillar_opts:.*/pillar_opts: False/' -i /etc/salt/master

# Configure the master's extension directory
echo 'Configuring salt-master extension directory ...'
sed -e 's|#extension_modules:.*|extension_modules: /etc/salt/_ext|' -i /etc/salt/master

# Configure the master's fileserver backends
echo 'Adding salt-master fileserver backends ...'
cat >> /etc/salt/master << EOF

# fileserver setup
file_roots:
  base:
    - /srv/salt/base
  vpc:
    - /srv/salt/vpc
  prod:
    - /srv/salt/prod
  test:
    - /srv/salt/test
  dev:
    - /srv/salt/dev

fileserver_backend:
  - roots
  - git

gitfs_remotes:
  - https://github.com/arashgorg/salt.git:
    - user: TBD
    - password: TBD

# pillar setup
ext_pillar:
  - dynamo:
      table: SaltPillar
      region: us-west-2
      id_field: id
EOF

# Make the /srv/salt directory
mkdir -p /srv/salt
chown admin.admin /srv/salt

# Point the minion to the loopback
echo 'Pointing salt-minion to 127.0.0.1 ...'
sed -e 's/#master:.*/master: 127.0.0.1/' -i /etc/salt/minion

# Bump the minion's log level to INFO
echo 'Setting salt-minion to log at INFO level ...'
sed -e 's/#log_level:.*/log_level: info/' -i /etc/salt/minion

# Upgrade other packages
echo 'Upgrading packages ...'
apt-get upgrade -y

# Setup Apache
apt-get -y install apache2

mkdir -p /srv/arash
chown admin.admin /srv/arash

aws s3 cp s3://cf-templates-4cmmx6wny0hn-us-west-2/salt/screen-shot1.png /srv/arash/screen-shot1.png
aws s3 cp s3://cf-templates-4cmmx6wny0hn-us-west-2/salt/screen-shot2.png /srv/arash/screen-shot2.png

cat >> /srv/arash/index.html << EOF

<HTML>
<BODY>
Hello AWS World
</BODY>
</HTML>
EOF

cat >> /srv/arash/InitialLaunch.sh << EOF

#!/bin/bash
if [ -f /srv/arash/Done.txt ]
then
	echo "already ran once, don't do anything"
else
	mkdir /ebs
	mkfs -t ext4 /dev/xvdf
	mount /dev/xvdf /ebs
	echo "/dev/xvdf /ebs ext4 defaults,nofail 0 2" >> /etc/fstab
	mkdir /ebs/www
	mkdir /ebs/www/html
	sed -i 's.DocumentRoot /var/www/html.DocumentRoot /ebs/www/html.g' /etc/apache2/sites-available/000-default.conf
	sed -i 's./var/www/./ebs/www/.g' /etc/apache2/apache2.conf

	cp /srv/arash/index.html /ebs/www/html/index.html
	cp /srv/arash/screen-shot1.png /ebs/www/html/screen-shot1.png
	cp /srv/arash/screen-shot2.png /ebs/www/html/screen-shot2.png
	
	echo "Done" >> /srv/arash/Done.txt
fi

service apache2 stop
service apache2 start
EOF

# Cleanup
echo 'Cleaning up ...'
apt-get clean


# Main AMI: ami-617d6f00 (11/29 5:07pm)
# Added apache auto-install and index.html creation  ami-b96072d8 (11:29 5:50 pm)
# New AMI: ami-62667403   (11/29 7:35 pm)  - final cleanup
# New AMI:  ami-b86476d9 (11/29 8:02 pm)  - minor cleanup (final)
# ami-31041650    (11/30/1:42 pm) - turned UserData into bash script
# ami-3c0f1d5d (11/30/2015 pm) - fixed mount on reboot
# Fixed Mount - ami-973220f6