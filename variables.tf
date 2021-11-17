# variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create the infrastructure resources for Confluent Platform
# https://www.terraform.io/docs/configuration/variables.html

# AWS EC2 KeyPair
variable "keypair_name" {
  description = "The AWS Key pair name."
}

variable "private_key" {
  description = "The AWS Private Key for Ansible instance to connect to other instances for Confluent deployment."
}


# Tags
variable "prefix" {
  description = "This prefix will be included in the name of the resources."
  default     = "Confluent"
}

variable "owner" {
  description = "This owner name tag will be included in the owner of the resources."
  default     = "Saurav Mitra"
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

variable "fixed_pvt_ip" {
  description = "Fixed Private IP's with all in the first private subnet."
  default     = true
}

# Instances
variable "ansible_instance" {
  description = "The Ansible Server Instance."
  default     = { instance_type : "t2.micro", pvt_ip : "10.0.0.10" }
}

variable "zookeeper_instances" {
  description = "The Zookeeper Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 3, pvt_ips : ["10.0.1.10", "10.0.1.11", "10.0.1.12"] }
}

variable "kafka_broker_instances" {
  description = "The Kafka Broker Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 3, pvt_ips : ["10.0.1.20", "10.0.1.21", "10.0.1.22"] }
}

variable "rest_proxy_instances" {
  description = "The REST Proxy Instances."
  default     = { instance_type : "t2.small", volume : 30, count : 1, pvt_ips : ["10.0.1.70"] }
}

variable "control_center_instances" {
  description = "The Control Center Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1, pvt_ips : ["10.0.1.50"] }
}

variable "schema_registry_instances" {
  description = "The Schema Registry Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1, pvt_ips : ["10.0.1.30"] }
}

variable "kafka_connect_instances" {
  description = "The Kafka Connect Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1, pvt_ips : ["10.0.1.40"] }
}

variable "ksql_instances" {
  description = "The KSQL Instances."
  default     = { instance_type : "t2.large", volume : 30, count : 1, pvt_ips : ["10.0.1.60"] }
}

variable "database_instance" {
  description = "The Database Server Instance."
  default     = { instance_type : "t2.xlarge", pvt_ip : "10.0.1.100" }
}

variable "db_password" {
  description = "The Database Admin Password."
  default     = "Password123456"
}


# OpenVPN Access Server
variable "openvpn_server_ami_name" {
  description = "The OpenVPN Access Server AMI Name."
  default     = "OpenVPN Access Server Community Image-fe8020db-5343-4c43-9e65-5ed4a825c931-ami-06585f7cf2fb8855c.4"
}

variable "openvpn_server_instance_type" {
  description = "The OpenVPN Access Server Instance Type."
  default     = "t2.micro"
}

variable "vpn_admin_user" {
  description = "The OpenVPN Admin User."
  default     = "openvpn"
}

variable "vpn_admin_password" {
  description = "The OpenVPN Admin Password."
}


# Twitter
variable "twitter_consumer_key" {
  description = "The Twitter Consumer Key."
}

variable "twitter_consumer_secret" {
  description = "The Twitter Consumer Secret."
}

variable "twitter_access_token" {
  description = "The Twitter Access Token."
}

variable "twitter_access_token_secret" {
  description = "The Twitter Access Token Secret."
}

variable "twitter_filter_tag" {
  description = "The Twitter Filter Tags."
  default     = "#covid19"
}
