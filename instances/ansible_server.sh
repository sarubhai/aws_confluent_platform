#!/bin/bash
# Name: ansible_server.sh
# Owner: Saurav Mitra
# Description: Configure Ansible Server & Run Confluent Platform Playbook

# Install Ansible
sudo yum -y install epel-release
sudo yum -y install ansible
# Install Git
sudo yum -y install git
# Git Clone cp-ansible
cd /home/centos
git clone --quiet https://github.com/confluentinc/cp-ansible
cd cp-ansible
git checkout 6.1.0-post

# Write to hosts.yml
function log () {
  echo "$@" >> hosts.yml
}


log "all:"
log "  vars:"
log "    ansible_connection: ssh"
log "    ansible_user: centos"
log "    ansible_become: true"
log "    ansible_ssh_private_key_file: /home/centos/.ssh/${keypair_name}.pem"
log "    ssl_enabled: true"
log "    ssl_mutual_auth_enabled: true"
log "    secrets_protection_enabled: true"


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
ansible-playbook -vvv -i hosts.yml all.yml --ssh-common-args='-o StrictHostKeyChecking=no' > failure.txt
