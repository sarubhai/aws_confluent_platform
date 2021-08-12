# Confluent platform deployment in AWS

Deploys Confluent platform in AWS using Terraform & Ansible

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

Ansible Controller Node Instance will be deployed in Public Subnet. All Confluent instances will be deployed in Private Subnet with fixed Private IP address.

The Demo Database Server Instance have multiple database types running as docker containers;

- Oracle XE 11g
- MySQL
- PostgreSQL
- Elasticsearch
- MongoDB
- Redis

The Kafka Connect Plugins that will be installed during deployment from Confluent Hub are:

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

- Peer-to-peer communication 2888
- Peer-to-peer communication 3888
- Client access 2181
- Client access via TLS 2182
- Jolokia [*] 7770

**Kafka Broker**

- Inter-broker listener 9091
- External listener 9092
- Metadata Service (MDS) 8090
- Confluent Server REST API 8090
- Jolokia [*] 7771

**REST Proxy**

- REST Proxy 8082

**Control Center**

- Control Center 9021

**Kafka Connect**

- REST API 8083
- Jolokia [*] 7773

**KSQL**

- REST API 8088
- Jolokia [*] 7774

**Schema Registry**

- REST API 8081
- Jolokia [*] 7772

**Common**

- SSH 22
- ICMP
- JMX 1099

[*] Reserve the Jolokia ports only when you deploy Confluent Platform using Ansible.

### Prerequisite

Terraform is already installed in local machine.

## Usage

- Clone this repository
- Setup Terraform Cloud Organisation & workspace. [https://app.terraform.io/](https://app.terraform.io/)
- Change the Terraform backend accordingly in backend.tf
- Generate & setup IAM user Access & Secret Key
- Generate a AWS EC2 Key Pair in the region where you want to deploy the Confluent platform
- Add the below variable values as Terraform Variables under workspace

### terraform.tfvars

```
private_key = "-----BEGIN RSA PRIVATE KEY----- content -----END RSA PRIVATE KEY-----"

keypair_name = "confluent-us-west-2"

db_password = "Password123456"

vpn_admin_password = "asdflkjhgqwerty1234"
```

- Add the below variable values as Environment Variables under workspace

### export

```
AWS_ACCESS_KEY_ID = "access_key"

AWS_SECRET_ACCESS_KEY = "secret_key"

AWS_DEFAULT_REGION = "us-west-2"
```

- Change other variables in variables.tf file if needed
- terraform init
- terraform plan
- terraform apply -auto-approve -refresh=false

- Login to openvpn_access_server_ip with user as openvpn & vpn_admin_password
- Download the VPN connection profile
- Download & use OpenVPN client to connect to AWS VPC.

- Finally browse the control center at [https://<control_center_public_ip>:9021](https://<control_center_public_ip>:9021)
