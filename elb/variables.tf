# Name: variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create ELB for Control Center & Kibana

variable "prefix" {
  description = "This prefix will be included in the name of the resources."
}

variable "owner" {
  description = "This owner name tag will be included in the name of the resources."
}

variable "public_subnet_id" {
  description = "The public subnets ID."
}

variable "elb_sg_id" {
  description = "Security Group for Elastic Load Balancer."
}

variable "control_center_instances_id" {
  description = "The Control Center Instances ID's."
}

variable "database_server_id" {
  description = "Database Server ID."
}
