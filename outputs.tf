# outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the relevant resources ID, ARN, URL values
# https://www.terraform.io/docs/configuration/outputs.html

# VPC & Subnet
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID."
}

output "public_subnet_id" {
  value       = module.vpc.public_subnet_id
  description = "The public subnets ID."
}

output "private_subnet_id" {
  value       = module.vpc.private_subnet_id
  description = "The private subnets ID."
}

# Security Groups
output "ansible_sg_id" {
  value       = module.sg.ansible_sg_id
  description = "Security Group for Ansible Server."
}

output "confluent_sg_id" {
  value       = module.sg.confluent_sg_id
  description = "Security Group for Confluent Platform."
}

# Instances
output "ansible_server_ip" {
  value       = module.instances.ansible_server_ip
  description = "Ansible Server IP."
}

output "zookeeper_instances_ip" {
  value       = module.instances.zookeeper_instances_ip
  description = "The Zookeeper Instances IP's."
}

output "kafka_broker_instances_ip" {
  value       = module.instances.kafka_broker_instances_ip
  description = "The Kafka Broker Instances IP's."
}

output "rest_proxy_instances_ip" {
  value       = module.instances.rest_proxy_instances_ip
  description = "The REST Proxy Instances IP's."
}

output "control_center_instances_ip" {
  value       = module.instances.control_center_instances_ip
  description = "The Control Center Instances IP's."
}

output "schema_registry_instances_ip" {
  value       = module.instances.schema_registry_instances_ip
  description = "The Schema Registry Instances IP's."
}

output "kafka_connect_instances_ip" {
  value       = module.instances.kafka_connect_instances_ip
  description = "The Kafka Connect Instances IP's."
}

output "ksql_instances_ip" {
  value       = module.instances.ksql_instances_ip
  description = "The KSQL Instances IP's."
}
