# main.tf
# Owner: Saurav Mitra
# Description: This terraform config will create the infrastructure resources for Confluent Platform

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
  private_subnet_id         = module.vpc.private_subnet_id
  fixed_pvt_ip              = var.fixed_pvt_ip
  ansible_sg_id             = module.sg.ansible_sg_id
  zookeeper_sg_id           = module.sg.zookeeper_sg_id
  kafka_sg_id               = module.sg.kafka_sg_id
  rest_proxy_sg_id          = module.sg.rest_proxy_sg_id
  control_center_sg_id      = module.sg.control_center_sg_id
  schema_registry_sg_id     = module.sg.schema_registry_sg_id
  kafka_connect_sg_id       = module.sg.kafka_connect_sg_id
  ksql_sg_id                = module.sg.ksql_sg_id
  database_sg_id            = module.sg.database_sg_id
  ansible_instance          = var.ansible_instance
  zookeeper_instances       = var.zookeeper_instances
  kafka_broker_instances    = var.kafka_broker_instances
  rest_proxy_instances      = var.rest_proxy_instances
  control_center_instances  = var.control_center_instances
  schema_registry_instances = var.schema_registry_instances
  kafka_connect_instances   = var.kafka_connect_instances
  ksql_instances            = var.ksql_instances
  keypair_name              = var.keypair_name
  private_key               = var.private_key
  database_instance         = var.database_instance
  db_password               = var.db_password
}



# Connect to VPC using OpenVPN Access Server
module "openvpn" {
  source                       = "./openvpn"
  prefix                       = var.prefix
  owner                        = var.owner
  vpc_id                       = module.vpc.vpc_id
  public_subnet_id             = module.vpc.public_subnet_id
  openvpn_server_ami_name      = var.openvpn_server_ami_name
  openvpn_server_instance_type = var.openvpn_server_instance_type
  vpn_admin_user               = var.vpn_admin_user
  vpn_admin_password           = var.vpn_admin_password
  keypair_name                 = var.keypair_name
}
