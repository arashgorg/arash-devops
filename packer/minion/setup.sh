#!/bin/bash

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive
PRIVATE_S3_URI=s3://cf-templates-4cmmx6wny0hn-us-west-2/salt

export AWS_ACCESS_KEY_ID=AKIAIWMEEJMJI3PPG4KQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=us-west-2

# Install awscli, salt-minion, and tools
echo 'Installing packages ...'
echo 'deb http://debian.saltstack.com/debian jessie-saltstack-2015-05 main' > /etc/apt/sources.list.d/saltstack.list
wget -q -O - 'http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key' | apt-key add -
echo 'deb http://packages.elasticsearch.org/logstashforwarder/debian stable main' > /etc/apt/sources.list.d/elasticsearch.list
wget -q -O - 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch' | apt-key add -
apt-get update
apt-get install -y curl dnsutils jq logstash-forwarder python-pip pv salt-minion sysstat tmux vim
pip install awscli

# Install node-exporter
mkdir -p /opt/node-exporter/bin
wget -q -O - https://github.com/prometheus/node_exporter/releases/download/0.11.0/node_exporter-0.11.0.linux-amd64.tar.gz | tar -C /opt/node-exporter/bin --no-same-owner -xzf -

# Stop the minion and cleanup any state it may have accrued
echo 'Stopping salt-minion ...'
systemctl stop salt-minion
rm -f /etc/salt/minion_id /etc/salt/pki/minion/minion_master.pub

# Auto-recover the minion when the master changes its IP address
echo 'Setting salt-minion to auto-recover on master IP address change ...'
sed -e 's/#auth_safemode:.*/auth_safemode: False/' -i /etc/salt/minion
sed -e 's/#ping_interval:.*/ping_interval: 1/' -i /etc/salt/minion
sed -e 's/#restart_on_error:.*/restart_on_error: True/' -i /etc/salt/minion

# Bump the minion's log level to INFO
echo 'Setting salt-minion to log at INFO level ...'
sed -e 's/#log_level:.*/log_level: info/' -i /etc/salt/minion

# Add minion custom grains directories
echo 'Adding salt-minion custom grains directories ...'
cat >> /etc/salt/minion << EOF

# custom grains
grains_dirs:
  - /etc/salt/_grains
EOF

# Install custom grains
#echo 'Installing custom grains ...'
#mkdir -p /etc/salt/_grains
#install -v /tmp/ec2_*.py /etc/salt/_grains

# Update the salt-minion unit file so that it starts after multi-user.target (cloud-init has completed)
#echo 'Configuring salt-minion to start after sysinit ...'
#sed -e 's/After=network\.target/After=multi-user.target/' -i /lib/systemd/system/salt-minion.service
#systemctl daemon-reload

# Install salt-minion-startup.service
#echo 'Installing salt-minion-startup.service ...'
#install -v -m 644 /tmp/salt-minion-startup.service /etc/systemd/system
#systemctl daemon-reload
#systemctl enable salt-minion-startup.service

# Upgrade other packages
echo 'Upgrading packages ...'
apt-get upgrade -y

# Cleanup
echo 'Cleaning up ...'
apt-get clean
#rm -f ~root/.ssh/authorized_keys ~admin/.ssh/authorized_keys
