# variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create the infrastructure resources for Confluent Platform
# https://www.terraform.io/docs/configuration/variables.html

# AWS Provider
variable "credentials_file" {
  description = "Path to the AWS access credentials file."
}

variable "profile" {
  description = "AWS Profile name in the AWS access credentials file."
}

# AWS EC2 KeyPair
variable "keypair_name" {
  description = "The AWS Key pair name."
}

variable "region" {
  description = "The region where the resources are created."
  default     = "us-west-2"
}


# Tags
variable "prefix" {
  description = "This prefix will be included in the name of the resources."
  default     = "Confluent"
}

variable "owner" {
  description = "This owner name tag will be included in the owner of the resources."
  default     = "Saurav"
}


# VPC & Subnets
variable "vpc_cidr_block" {
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A map of availability zones to CIDR blocks to use for the public subnet."
  default = {
    us-west-2a = "10.0.0.0/24"
  }
}

variable "private_subnets" {
  description = "A map of availability zones to CIDR blocks to use for the private subnet."
  default = {
    us-west-2a = "10.0.1.0/24"
    us-west-2b = "10.0.2.0/24"
    us-west-2c = "10.0.3.0/24"
  }
}

variable "internet_cidr_block" {
  description = "The address space that is used by the internet."
  default     = "0.0.0.0/0"
}

# Instances
variable "ansible_instance_type" {
  description = "The Ansible Server Instance Type."
  default     = "t2.micro"
}

variable "zookeeper_instances" {
  description = "The Zookeeper Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 3 }
}

variable "kafka_broker_instances" {
  description = "The Kafka Broker Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 3 }
}

variable "rest_proxy_instances" {
  description = "The REST Proxy Instances."
  default     = { instance_type : "t2.small", volume : 30, count : 1 }
}

variable "control_center_instances" {
  description = "The Control Center Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1 }
}

variable "schema_registry_instances" {
  description = "The Schema Registry Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1 }
}

variable "kafka_connect_instances" {
  description = "The Kafka Connect Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1 }
}

variable "ksql_instances" {
  description = "The KSQL Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1 }
}

variable "database_instance_type" {
  description = "The Database Server Instance Type."
  default     = "t2.large"
}

variable "oracle_password" {
  description = "The Oracle Password."
  default     = "Password123456"
}
