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
git checkout 6.2.0-post
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
# log "    ssl_mutual_auth_enabled: false"
# log "    secrets_protection_enabled: true"
log "    health_checks_enabled: true"
log "    sasl_protocol: plain"
log "    jmxexporter_enabled: true"
log "    kafka_broker_schema_validation_enabled: true"

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
log "    - jcustenborder/kafka-connect-spooldir:latest"
log "    - jcustenborder/kafka-connect-twitter:latest"
log "    - confluentinc/kafka-connect-http:latest"
log "    - confluentinc/kafka-connect-s3:latest"

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



# TWITTER TWEETS KAFKA PRODUCER
mkdir /home/centos/twitter
cd /home/centos/twitter

scp -i /home/centos/.ssh/${keypair_name}.pem centos@10.0.1.20:/var/ssl/private/ca.crt /home/centos/twitter/ca.crt

sudo yum -y install python3-pip >> /dev/null

sudo tee /home/centos/twitter/requirements.txt &>/dev/null <<EOF
# Python Packages
kafka-python
tweepy
EOF

pip3 install -r requirements.txt -t ./

sudo chown -R centos:centos /home/centos/twitter

# rest_proxy='https://10.0.1.70:8082'
# curl -s -k -X POST -H "Content-Type: application/vnd.kafka.v2+json" $rest_proxy/topics --data '{"topic_name": "tweets", "partitions_count": 1, "replication_factor": 2, "configs": [{"name": "cleanup.policy", "value": "delete"},{"name": "retention.ms", "value": 3600000}]}'
kafka_cluster='https://10.0.1.20:8090'
cluster_id=`curl -s -k -X GET $kafka_cluster/kafka/v3/clusters | jq -r '.data[0].cluster_id'`
curl -s -k -X POST -H "Content-Type: application/json" $kafka_cluster/kafka/v3/clusters/$cluster_id/topics --data '{"topic_name": "tweets", "partitions_count": 1, "replication_factor": 2, "configs": [{"name": "cleanup.policy", "value": "delete"},{"name": "retention.ms", "value": 3600000}]}'
curl -s -k -X POST -H "Content-Type: application/json" $kafka_cluster/kafka/v3/clusters/$cluster_id/topics --data '{"topic_name": "oracle-redo-log-topic", "partitions_count": 1, "replication_factor": 2, "configs": [{"name": "cleanup.policy", "value": "delete"},{"name": "retention.ms", "value": 120960000}]}'


schema_registry='https://10.0.1.30:8081'
curl -s -k -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" $schema_registry/subjects/tweets-value/versions --data '{"schemaType": "JSON", "schema": "{\"type\": \"object\", \"additionalProperties\": false, \"properties\": { \"tweet_text\": {\"type\": \"string\"}, \"created_at\": {\"type\": \"string\"}, \"user_id\": {\"type\": \"integer\"}, \"user_name\": {\"type\": \"string\"}, \"user_screen_name\": {\"type\": \"string\"}, \"user_followers_count\": {\"type\": \"integer\"}, \"tweet_body\": {\"type\": \"string\"}, \"user_description\": {\"type\": \"string\"}, \"user_location\": {\"type\": \"string\"} } }"}'


sudo tee /home/centos/twitter/tweets_kafka.py &>/dev/null <<EOF
import json
import os
import tweepy
from kafka import KafkaProducer

consumer_key = os.environ['CONSUMER_KEY']
consumer_secret = os.environ['CONSUMER_SECRET']
access_token = os.environ['ACCESS_TOKEN']
access_token_secret = os.environ['ACCESS_TOKEN_SECRET']
twitter_filter_tag = os.environ['TWITTER_FILTER_TAG']

bootstrap_servers = os.environ['BOOTSTRAP_SERVERS']
sasl_username = os.environ['SASL_USERNAME']
sasl_password = os.environ['SASL_PASSWORD']
kafka_topic_name = os.environ['KAFKA_TOPIC_NAME']


class StreamingTweets(tweepy.Stream):
    def on_status(self, status):
        data = {
            'tweet_text': status.text,
            'created_at': str(status.created_at),
            'user_id': status.user.id,
            'user_name': status.user.name,
            'user_screen_name': status.user.screen_name,
            'user_description': status.user.description,
            'user_location': status.user.location,
            'user_followers_count': status.user.followers_count,
            'tweet_body': json.dumps(status._json)
        }

        response = producer.send(
            kafka_topic_name, json.dumps(data).encode('utf-8'))

        print((response))

    def on_error(self, status):
        print(status)


producer = KafkaProducer(bootstrap_servers=bootstrap_servers, security_protocol='SASL_SSL', ssl_cafile='ca.crt', ssl_check_hostname=False, sasl_mechanism='PLAIN', sasl_plain_username=sasl_username, sasl_plain_password=sasl_password)

stream = StreamingTweets(
    consumer_key, consumer_secret,
    access_token, access_token_secret
)

stream.filter(track=[twitter_filter_tag])
EOF

export CONSUMER_KEY=${twitter_consumer_key}
export CONSUMER_SECRET=${twitter_consumer_secret}
export ACCESS_TOKEN=${twitter_access_token}
export ACCESS_TOKEN_SECRET=${twitter_access_token_secret}
export TWITTER_FILTER_TAG=${twitter_filter_tag}
export BOOTSTRAP_SERVERS='ip-10-0-1-20.us-west-2.compute.internal:9092,ip-10-0-1-21.us-west-2.compute.internal:9092,ip-10-0-1-22.us-west-2.compute.internal:9092'
export SASL_USERNAME='admin'
export SASL_PASSWORD='admin-secret'
export KAFKA_TOPIC_NAME='tweets'

nohup python3 tweets_kafka.py > nohup.out &
exit

touch /home/centos/done.out
