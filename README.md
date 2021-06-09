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
