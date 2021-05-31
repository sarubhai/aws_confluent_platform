# Name: variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create EC2 intances for Ansible Node & Confluent Platform

variable "prefix" {
  description = "This prefix will be included in the name of the resources."
}

variable "owner" {
  description = "This owner name tag will be included in the name of the resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "public_subnet_id" {
  description = "The public subnets ID."
}

variable "ansible_sg_id" {
  description = "Security Group for Ansible Server."
}

variable "confluent_sg_id" {
  description = "Security Group for Confluent Platform."
}

variable "ansible_instance_type" {
  description = "The Ansible Server Instance Type."
}

variable "zookeeper_instances" {
  description = "The Zookeeper Instances."
}

variable "kafka_broker_instances" {
  description = "The Kafka Broker Instances."
}

variable "rest_proxy_instances" {
  description = "The REST Proxy Instances."
}

variable "control_center_instances" {
  description = "The Control Center Instances."
}

variable "schema_registry_instances" {
  description = "The Schema Registry Instances."
}

variable "kafka_connect_instances" {
  description = "The Kafka Connect Instances."
}

variable "ksql_instances" {
  description = "The KSQL Instances."
}

variable "keypair_name" {
  description = "The AWS Key pair name."
}
