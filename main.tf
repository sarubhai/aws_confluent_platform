# main.tf
# Owner: Saurav Mitra
# Description: This terraform config will create the infrastructure resources for Confluent Platform


# Configure Terraform 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure AWS Provider
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
# $ export AWS_ACCESS_KEY_ID="AccessKey"
# $ export AWS_SECRET_ACCESS_KEY="SecretKey"

provider "aws" {
  shared_credentials_file = var.credentials_file
  profile                 = var.profile
  region                  = var.region
}


# VPC & Subnets
module "vpc" {
  source          = "./vpc"
  prefix          = var.prefix
  owner           = var.owner
  vpc_cidr_block  = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# Security Groups
module "sg" {
  source              = "./sg"
  prefix              = var.prefix
  owner               = var.owner
  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = var.vpc_cidr_block
  internet_cidr_block = var.internet_cidr_block
}

# Instances
module "instances" {
  source                    = "./instances"
  prefix                    = var.prefix
  owner                     = var.owner
  vpc_id                    = module.vpc.vpc_id
  public_subnet_id          = module.vpc.public_subnet_id
  ansible_sg_id             = module.sg.ansible_sg_id
  confluent_sg_id           = module.sg.confluent_sg_id
  ansible_instance_type     = var.ansible_instance_type
  zookeeper_instances       = var.zookeeper_instances
  kafka_broker_instances    = var.kafka_broker_instances
  rest_proxy_instances      = var.rest_proxy_instances
  control_center_instances  = var.control_center_instances
  schema_registry_instances = var.schema_registry_instances
  kafka_connect_instances   = var.kafka_connect_instances
  ksql_instances            = var.ksql_instances
  keypair_name              = var.keypair_name
}