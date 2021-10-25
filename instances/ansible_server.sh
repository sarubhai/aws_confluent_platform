#!/bin/bash
# Name: ansible_server.sh
# Owner: Saurav Mitra
# Description: Configure Ansible Server & Run Confluent Platform Playbook

# Install Ansible
sudo yum -y update
sudo yum -y install epel-release
sudo yum -y install ansible
# Install Git
sudo yum -y install git
# Git Clone cp-ansible
cd /home/centos
git clone --quiet https://github.com/confluentinc/cp-ansible
cd cp-ansible
git checkout 6.2.1-post
sudo chown -R centos:centos /home/centos/cp-ansible

# Add Private Key File
echo "${private_key}" > /home/centos/.ssh/${keypair_name}.pem
sudo chmod 400 /home/centos/.ssh/${keypair_name}.pem
sudo chown centos:centos /home/centos/.ssh/${keypair_name}.pem

# Write to hosts.yml
function log () {
  echo "$@" >> hosts.yml
}

export ANSIBLE_HOST_KEY_CHECKING=False

log "all:"
log "  vars:"
log "    ansible_connection: ssh"
log "    ansible_user: centos"
log "    ansible_become: true"
log "    ansible_ssh_private_key_file: /home/centos/.ssh/${keypair_name}.pem"
log "    ssl_enabled: true"
log "    ssl_mutual_auth_enabled: true"
log "    secrets_protection_enabled: true"
log "    health_checks_enabled: true"
log "    sasl_protocol: plain"


log "zookeeper:"
log "  hosts:"
%{ for index, addr in zookeeper_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(zookeeper_pub, index)}"
%{ endfor ~}

log "kafka_broker:"
log "  hosts:"
%{ for index, addr in kafka_broker_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(kafka_broker_pub, index)}"
%{ endfor ~}

log "kafka_rest:"
log "  hosts:"
%{ for index, addr in rest_proxy_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(rest_proxy_pub, index)}"
%{ endfor ~}

log "control_center:"
log "  hosts:"
%{ for index, addr in control_center_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(control_center_pub, index)}"
%{ endfor ~}

log "schema_registry:"
log "  hosts:"
%{ for index, addr in schema_registry_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(schema_registry_pub, index)}"
%{ endfor ~}

log "kafka_connect:"
log "  vars:"
log "    kafka_connect_confluent_hub_plugins:"
log "    - confluentinc/kafka-connect-jdbc:latest"
log "    - confluentinc/kafka-connect-oracle-cdc:latest"
log "    - debezium/debezium-connector-mysql:latest"
log "    - debezium/debezium-connector-postgresql:latest"
log "    - debezium/debezium-connector-sqlserver:latest"
log "    - debezium/debezium-connector-mongodb:latest"
log "    - confluentinc/kafka-connect-elasticsearch:latest"
log "    - mongodb/kafka-connect-mongodb:latest"
log "    - jcustenborder/kafka-connect-redis:latest"
log "    - confluentinc/kafka-connect-http:latest"

log "  hosts:"
%{ for index, addr in kafka_connect_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(kafka_connect_pub, index)}"
%{ endfor ~}

log "ksql:"
log "  hosts:"
%{ for index, addr in ksql_pvt ~}
log "    ${addr}:"
# log "      ansible_host: ${element(ksql_pub, index)}"
%{ endfor ~}

# Run Ansible Playbook
ansible-playbook -vvv -i hosts.yml all.yml --ssh-common-args='-o StrictHostKeyChecking=no' > cp-ansible-log.txt

# Install jq
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y update
sudo yum -y install jq

sudo chown -R centos:centos /home/centos/cp-ansible
