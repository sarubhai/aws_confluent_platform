# Name: confluent.tf
# Owner: Saurav Mitra
# Description: This terraform config will create EC2 instances for Confluent Platform


# Confluent AMI Filter
data "aws_ami" "confluent_centos" {
  owners      = ["679593333241"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# EC2 Instances
resource "aws_instance" "zookeeper" {
  count = var.zookeeper_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.zookeeper_instances["instance_type"]
  subnet_id                   = var.private_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.zookeeper_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-zookeeper-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "kafka_broker" {
  count = var.kafka_broker_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.kafka_broker_instances["instance_type"]
  subnet_id                   = var.private_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.kafka_broker_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-kafka-broker-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "rest_proxy" {
  count = var.rest_proxy_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.rest_proxy_instances["instance_type"]
  subnet_id                   = var.private_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.rest_proxy_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-rest-proxy-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "control_center" {
  count = var.control_center_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.control_center_instances["instance_type"]
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.control_center_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-control-center-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "schema_registry" {
  count = var.schema_registry_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.schema_registry_instances["instance_type"]
  subnet_id                   = var.private_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.schema_registry_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-schema-registry-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "kafka_connect" {
  count = var.kafka_connect_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.kafka_connect_instances["instance_type"]
  subnet_id                   = var.private_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.kafka_connect_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-kafka-connect-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "ksql" {
  count = var.ksql_instances["count"]
  ami                         = data.aws_ami.confluent_centos.id
  instance_type               = var.ksql_instances["instance_type"]
  subnet_id                   = var.private_subnet_id[0]
  vpc_security_group_ids      = [var.confluent_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = var.ksql_instances["volume"]
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-ksql-${count.index + 1}"
    Owner = var.owner
  }
}
