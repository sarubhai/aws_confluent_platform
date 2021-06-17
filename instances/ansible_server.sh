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
git checkout 6.1.0-post

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


connect=${fixed_pvt_ip}
if [ "$connect" = true ] ; then
#######################################
# Upload Sample Kafaka Connector Config
#######################################
# Connector: JdbcSourceConnector; Source: Oracle
# Scenario: Bulk Load Single Table (EMPLOYEES) to Kafka Topic (EMPLOYEES); Poll after 24 hours;
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "jdbc-src-orcl-emp-bulk",
  "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
  "connection.url": "jdbc:oracle:thin:@10.0.1.100:1521/XE",
  "connection.user": "orcl_user",
  "connection.password": "${oracle_password}",
  "table.whitelist": "ORCL_USER.EMPLOYEES",
  "numeric.mapping": "best_fit",
  "mode": "bulk",
  "table.types": "TABLE",
  "poll.interval.ms": "86400000"
}' https://10.0.1.40:8083/connectors/jdbc-src-orcl-emp-bulk/config | jq .

# Connector: JdbcSinkConnector; Target: Oracle
# Scenario: Insert from Kafka Topic (EMPLOYEES) to existing Table (EMPLOYEES);
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "jdbc-sink-orcl-emp-insert",
  "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
  "topics": "EMPLOYEES",
  "connection.url": "jdbc:oracle:thin:@10.0.1.100:1525/XE",
  "connection.user": "orcl_user",
  "connection.password": "${oracle_password}",
  "insert.mode": "insert",
  "table.types": "TABLE",
  "table.name.format": "EMPLOYEES"
}' https://10.0.1.40:8083/connectors/jdbc-sink-orcl-emp-insert/config | jq .

# Connector: JdbcSourceConnector; Source: Oracle
# Scenario: Incremental Extraction Single Table (CONSULTANTS) to Kafka Topic (BUS-CONSULTANTS);
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "jdbc-src-orcl-cnslts-incr",
  "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
  "connection.url": "jdbc:oracle:thin:@10.0.1.100:1521/XE",
  "connection.user": "orcl_user",
  "connection.password": "${oracle_password}",
  "table.whitelist": "ORCL_USER.CONSULTANTS",
  "numeric.mapping": "best_fit",
  "mode": "timestamp+incrementing",
  "incrementing.column.name": "ID",
  "timestamp.column.name": "UPDATED_AT",
  "table.types": "TABLE",
  "topic.prefix": "BUS-"
}' https://10.0.1.40:8083/connectors/jdbc-src-orcl-cnslts-incr/config | jq .

# Connector: JdbcSinkConnector; Target: Oracle
# Scenario: Upsert from Kafka Topic (BUS-CONSULTANTS) to existing Table (CONSULTANTS);
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "jdbc-sink-orcl-cnslts-upsert",
  "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
  "topics": "BUS-CONSULTANTS",
  "connection.url": "jdbc:oracle:thin:@10.0.1.100:1525/XE",
  "connection.user": "orcl_user",
  "connection.password": "${oracle_password}",
  "dialect.name": "OracleDatabaseDialect",
  "insert.mode": "upsert",
  "table.types": "TABLE",
  "table.name.format": "CONSULTANTS",
  "pk.mode": "record_value",
  "pk.fields": "ID"
}' https://10.0.1.40:8083/connectors/jdbc-sink-orcl-cnslts-upsert/config | jq .

# Connector: JdbcSinkConnector; Target: Postgres
# Scenario: Insert from Kafka Topic (EMPLOYEES) to Table (employees); Create DDL;
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "jdbc-sink-postgres-emp-insert",
  "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
  "topics": "EMPLOYEES",
  "connection.url": "jdbc:postgresql://10.0.1.100:5432/postgres",
  "connection.user": "postgres",
  "connection.password": "${oracle_password}",
  "insert.mode": "insert",
  "table.name.format": "employees",
  "auto.create": "true"
}' https://10.0.1.40:8083/connectors/jdbc-sink-postgres-emp-insert/config | jq .

# Connector: MySqlConnector; Source: MySQL
# Scenario: CDC All Tables in Schema (sales) to respective Kafka Topics (e.g. sales_sales_product);
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "debezium-mysql-src-mysql-sales-cdc",
  "connector.class": "io.debezium.connector.mysql.MySqlConnector",
  "database.hostname": "10.0.1.100",
  "database.port": "3306",
  "database.user": "root",
  "database.password": "${oracle_password}",
  "database.server.name": "sales",
  "database.history.kafka.bootstrap.servers": "ip-10-0-1-20.us-west-2.compute.internal:9092,ip-10-0-1-21.us-west-2.compute.internal:9092,ip-10-0-1-22.us-west-2.compute.internal:9092",
  "database.history.kafka.topic": "dbhistory.sales",
  "include.schema.changes": false,
  "database.include.list": "sales",
  "database.history.producer.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"kafka_connect\" password=$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/producer.sasl.jaas.config/org.apache.kafka.common.security.plain.PlainLoginModule/password};",
  "database.history.producer.sasl.mechanism": "PLAIN",
  "database.history.producer.security.protocol": "SASL_SSL",
  "database.history.producer.ssl.keystore.location": "/var/ssl/private/kafka_connect.keystore.jks",
  "database.history.producer.ssl.keystore.password": "$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/producer.ssl.keystore.password}",
  "database.history.producer.ssl.truststore.location": "/var/ssl/private/kafka_connect.truststore.jks",
  "database.history.producer.ssl.truststore.password": "$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/producer.ssl.truststore.password}",
  "database.history.producer.ssl.key.password": "$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/producer.ssl.key.password}",
  "database.history.consumer.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"kafka_connect\" password=$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/consumer.sasl.jaas.config/org.apache.kafka.common.security.plain.PlainLoginModule/password};",
  "database.history.consumer.sasl.mechanism": "PLAIN",
  "database.history.consumer.security.protocol": "SASL_SSL",
  "database.history.consumer.ssl.keystore.location": "/var/ssl/private/kafka_connect.keystore.jks",
  "database.history.consumer.ssl.keystore.password": "$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/consumer.ssl.keystore.password}",
  "database.history.consumer.ssl.truststore.location": "/var/ssl/private/kafka_connect.truststore.jks",
  "database.history.consumer.ssl.truststore.password": "$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/consumer.ssl.truststore.password}",
  "database.history.consumer.ssl.key.password": "$$${securepass:/var/ssl/private/security.properties:connect-distributed.properties/consumer.ssl.key.password}",
  "transforms": "RemoveDots",
  "transforms.RemoveDots.type": "org.apache.kafka.connect.transforms.RegexRouter",
  "transforms.RemoveDots.regex": "(.*)\\.(.*)\\.(.*)",
  "transforms.RemoveDots.replacement": "$1_$2_$3"
}' https://10.0.1.40:8083/connectors/debezium-mysql-src-mysql-sales-cdc/config | jq . >> /home/centos/test.txt

# Connector: MongoSinkConnector; Target: MongoDB
# Scenario: Insert from Kafka Topic (sales_sales_product) to Collection (products);
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "mongo-sink-mongo-prod-insert",
  "connector.class": "com.mongodb.kafka.connect.MongoSinkConnector",
  "topics": "sales_sales_product",
  "connection.uri": "mongodb://root:${oracle_password}@10.0.1.100:27017",
  "database": "admin",
  "collection": "products"
}' https://10.0.1.40:8083/connectors/mongo-sink-mongo-prod-insert/config | jq .

# Connector: ElasticsearchSinkConnector; Target: Elasticsearch
# Scenario: Insert/Update from Kafka Topic (sales_sales_product) to Index (products);
curl -X PUT -k -H "Content-Type: application/json" --data '{
  "name": "elastic-sink-elastic-prod-upsert",
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "transforms": "dropPrefix",
  "topics": "sales_sales_product",
  "connection.url": "http://10.0.1.100:9200",
  "connection.username": "elastic",
  "connection.password": "${oracle_password}",
  "write.method": "UPSERT",
  "key.ignore": "true",
  "schema.ignore":"true",
  "compact.map.entries": "true",
  "transforms.dropPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
  "transforms.dropPrefix.regex":"sales_sales_(.*)",
  "transforms.dropPrefix.replacement":"$1"
}' https://10.0.1.40:8083/connectors/elastic-sink-elastic-prod-upsert/config | jq .


# curl -X GET -k https://10.0.1.40:8083/connector-plugins | jq .
# curl -X GET -k https://10.0.1.40:8083/connectors | jq .
# curl -X GET -k https://10.0.1.40:8083/connectors/jdbc-src-orcl-emp-bulk/status | jq .

fi
