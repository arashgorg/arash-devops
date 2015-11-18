#!/bin/bash

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive
PRIVATE_S3_URI=s3://cf-templates-4cmmx6wny0hn-us-west-2/salt

export AWS_ACCESS_KEY_ID=AKIAIWMEEJMJI3PPG4KQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=us-west-2

# Install /usr/local/bin scripts
#echo 'Installing /usr/local/bin/scripts ...'
#install -v -m 755 /tmp/update-route53-record /usr/local/bin

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

# Replace the master's key pair
#echo 'Installing salt-master key pair ...'
#aws s3 cp $PRIVATE_S3_URI/newgitkey.pub /etc/salt/pki/master/newgitkey.pub
#aws s3 cp $PRIVATE_S3_URI/newgitkey /etc/salt/pki/master/newgitkey
#chmod 400 /etc/salt/pki/master/newgitkey

# Install the master's SSH key pair for github access
echo 'Installing salt-master SSH key pair for github.com ...'
mkdir -p ~root/.ssh
aws s3 cp $PRIVATE_S3_URI/newgitkey.pub ~root/.ssh/newgitkey.pub
aws s3 cp $PRIVATE_S3_URI/newgitkey ~root/.ssh/newgitkey
chmod 400 ~root/.ssh/newgitkey

# Run the master in open mode (changed this)
#echo 'Setting salt-master to run in open mode ...'
#sed -e 's/#open_mode:.*/open_mode: True/' -i /etc/salt/master

# Auto-accept keys at the master
echo 'Setting salt-master to auto-accept keys ...'
sed -e 's/#auto_accept:.*/auto_accept: True/' -i /etc/salt/master

# Don't add the master's config data to pillars
#echo 'Disabling salt-master data in pillars ...'
#sed -e 's/#pillar_opts:.*/pillar_opts: False/' -i /etc/salt/master

# Configure the master's extension directory
#echo 'Configuring salt-master extension directory ...'
#sed -e 's|#extension_modules:.*|extension_modules: /etc/salt/_ext|' -i /etc/salt/master

# Install extensions
#echo 'Installing extensions ...'
#mkdir -p /etc/salt/_ext/pillar
#install -v /tmp/*_pillar.py /etc/salt/_ext/pillar

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
    - user: arashgorg
    - password: operations1

EOF

# Make the /srv/salt directory
#mkdir -p /srv/salt
#chown admin.admin /srv/salt

# Point the minion to the loopback
echo 'Pointing salt-minion to 127.0.0.1 ...'
sed -e 's/#master:.*/master: 127.0.0.1/' -i /etc/salt/minion

# Bump the minion's log level to INFO
echo 'Setting salt-minion to log at INFO level ...'
sed -e 's/#log_level:.*/log_level: info/' -i /etc/salt/minion

# Install custom grains
#echo 'Installing custom grains ...'
#mkdir -p /etc/salt/_grains
#install -v /tmp/ec2_*.py /etc/salt/_grains

# Install salt-master-discovery.service
#echo 'Installing salt-master-discovery.service ...'
#install -v -m 644 salt-master-discovery.service /etc/systemd/system
#systemctl daemon-reload
#systemctl enable salt-master-discovery.service

# Update the salt-master and salt-minion unit files so that they start after multi-user.target (cloud-init has completed)
#echo 'Configuring salt-master and salt-minion to start after sysinit ...'
#sed -e 's/After=network\.target/After=multi-user.target/' -i /lib/systemd/system/salt-master.service
#sed -e 's/After=network\.target/After=salt-master.service/' -i /lib/systemd/system/salt-minion.service
#sed -e 's/WantedBy=multi-user\.target/WantedBy=salt-master.service/' -i /lib/systemd/system/salt-minion.service
#systemctl daemon-reload

# Install salt-minion-startup.service
#echo 'Installing salt-minion-startup.service ...'
#install -v -m 644 salt-minion-startup.service /etc/systemd/system
#systemctl daemon-reload
#systemctl enable salt-minion-startup.service

# Upgrade other packages
echo 'Upgrading packages ...'
apt-get upgrade -y

# Cleanup
echo 'Cleaning up ...'
apt-get clean
#rm -f ~root/.ssh/authorized_keys ~admin/.ssh/authorized_keys
