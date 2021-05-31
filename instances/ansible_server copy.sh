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
cd /root
git clone --quiet https://github.com/confluentinc/cp-ansible
cd cp-ansible
git checkout 6.1.0-post

# Write to hosts.yml
function log () {
  echo "${@}" >> hosts.yml
}


log "all:"
log "  vars:"
log "    ansible_connection: ssh"
log "    ansible_user: ec2-user"
log "    ansible_become: true"
log "    ansible_ssh_private_key_file: /root/.ssh/${keypair_name}.pem"
log "    ssl_enabled: true"
log "    ssl_mutual_auth_enabled: true"
log "    zookeeper_ssl_enabled: true"
log "    zookeeper_ssl_mutual_auth_enabled: true"


log "zookeeper:"
log "  hosts:"
zookeeper_pvt_array=($(echo ${zookeeper_pvt} | tr "," "\n"))
zookeeper_pub_array=($(echo ${zookeeper_pub} | tr "," "\n"))
nodes=`echo ${#zookeeper_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${zookeeper_pvt_array[n]}:"
    log "      ansible_host: ${zookeeper_pub_array[n]}"
done


log "kafka_broker:"
log "  hosts:"
kafka_broker_pvt_array=($(echo ${kafka_broker_pvt} | tr "," "\n"))
kafka_broker_pub_array=($(echo ${kafka_broker_pub} | tr "," "\n"))
nodes=`echo ${#kafka_broker_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${kafka_broker_pvt_array[n]}:"
    log "      ansible_host: ${kafka_broker_pub_array[n]}"
done


log "kafka_rest:"
log "  hosts:"
rest_proxy_pvt_array=($(echo ${rest_proxy_pvt} | tr "," "\n"))
rest_proxy_pub_array=($(echo ${rest_proxy_pub} | tr "," "\n"))
nodes=`echo ${#rest_proxy_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${rest_proxy_pvt_array[n]}:"
    log "      ansible_host: ${rest_proxy_pub_array[n]}"
done


log "control_center:"
log "  hosts:"
control_center_pvt_array=($(echo ${control_center_pvt} | tr "," "\n"))
control_center_pub_array=($(echo ${control_center_pub} | tr "," "\n"))
nodes=`echo ${#control_center_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${control_center_pvt_array[n]}:"
    log "      ansible_host: ${control_center_pub_array[n]}"
done


log "schema_registry:"
log "  hosts:"
schema_registry_pvt_array=($(echo ${schema_registry_pvt} | tr "," "\n"))
schema_registry_pub_array=($(echo ${schema_registry_pub} | tr "," "\n"))
nodes=`echo ${#schema_registry_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${schema_registry_pvt_array[n]}:"
    log "      ansible_host: ${schema_registry_pub_array[n]}"
done


log "kafka_connect:"
log "  hosts:"
kafka_connect_pvt_array=($(echo ${kafka_connect_pvt} | tr "," "\n"))
kafka_connect_pub_array=($(echo ${kafka_connect_pub} | tr "," "\n"))
nodes=`echo ${#kafka_connect_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${kafka_connect_pvt_array[n]}:"
    log "      ansible_host: ${kafka_connect_pub_array[n]}"
done


log "ksql:"
log "  hosts:"
ksql_pvt_array=($(echo ${ksql_pvt} | tr "," "\n"))
ksql_pub_array=($(echo ${ksql_pub} | tr "," "\n"))
nodes=`echo ${#ksql_pvt_array[@]}`
for (( n=0; n<${nodes}; n++ ))
do
    log "    ${ksql_pvt_array[n]}:"
    log "      ansible_host: ${ksql_pub_array[n]}"
done


# Run Playbook
chmod 400 /root/.ssh/${keypair_name}.pem
ansible-playbook -vvv -i hosts.yml all.yml --ssh-common-args='-o StrictHostKeyChecking=no' > failure.txt



