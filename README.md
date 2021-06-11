# Confluent platform deployment in AWS
Deploys Confluent platform in AWS  using Terraform & Ansible

### Reference
CP-Ansible
- [https://github.com/confluentinc/cp-ansible](https://github.com/confluentinc/cp-ansible)

The Instances & Services that will be deployed from this repository are:
- Ansible Controller Node Instance
- Zookeeper Instances
- Kafka Broker Instances
- REST Proxy Instances
- Confluent Control Center Instances
- Schema Registry Instances
- Kafka Connect Instances
- KSQL Server Instances
- Demo Database Server Instance

Ansible Controller Node & Confluent Control Center Instances are deployed in Public Subnet, and rest of all the instances are deployed in Private Subnet.
Use the Ansible Controller Node as a Jump server to connect to other Instances in Private Subnet.

The Demon Database Server Instance have multiple database types running as docker containers;
- Oracle XE 11g
- MySQL
- PostgreSQL
- Elasticsearch
- MongoDB
- Redis

The Kafka Connect Plugins installed during deployment from Confluent Hub are:
- confluentinc/kafka-connect-jdbc
- confluentinc/kafka-connect-oracle-cdc
- debezium/debezium-connector-mysql
- debezium/debezium-connector-postgresql
- confluentinc/kafka-connect-elasticsearch
- mongodb/kafka-connect-mongodb
- jcustenborder/kafka-connect-redis
- confluentinc/kafka-connect-http

#### Confluent Service Ports
**ZooKeeper**
- Peer-to-peer communication	2888
- Peer-to-peer communication	3888
- Client access	                2181
- Client access via TLS	        2182
- Jolokia [*]	                7770

**Kafka Broker**
- Inter-broker listener	        9091
- External listener	            9092
- Metadata Service (MDS)	    8090
- Confluent Server REST API	    8090
- Jolokia [*]	                7771

**REST Proxy**
- REST Proxy	                8082

**Control Center**
- Control Center	            9021

**Kafka Connect**
- REST API	                    8083
- Jolokia [*]	                7773
	
**KSQL**
- REST API	                    8088
- Jolokia [*]	                7774
	
**Schema Registry**
- REST API	                    8081
- Jolokia [*]	                7772
	
**Common**
- SSH	                        22
- ICMP	
- JMX	                        1099

### Prerequisite
Terraform is already installed
## Usage
- Clone this repository
- Copy your AWS Keypair pem file (private key) under instances directory
- Add the below variable values in terraform.tfvars file under the root directory

### terraform.tfvars
```
credentials_file = "/Users/JohnDoe/.aws/credentials"

profile = "Confluent-IAM"

keypair_name = "confluent-us-west-2"
```
- Change other variables in variables.tf file if needed
- terraform init
- terraform plan
- terraform apply -auto-approve -refresh=false

Finally browse the control center at [https://<control_center_instance_ip>:9021](https://<control_center_instance_ip>:9021)
