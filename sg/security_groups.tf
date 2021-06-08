# Name: security_groups.tf
# Owner: Saurav Mitra
# Description: This terraform config will create the Security Groups for Ansible Server, Confluent Platform & Demo Database Server

# Create Ansible Security Group
resource "aws_security_group" "ansible_sg" {
  name        = "${var.prefix}_ansible_sg"
  description = "Security Group for Ansible Server"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name  = "${var.prefix}-ansible-sg"
    Owner = var.owner
  }
}

# Create Confluent Platform Security Group
resource "aws_security_group" "confluent_sg" {
  name        = "${var.prefix}_confluent_sg"
  description = "Security Group for Confluent Platform"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }
  
  # Zookeeper
  ingress {
    description = "Zookeeper Peer-to-peer communication"
    from_port   = 2888
    to_port     = 2888
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Zookeeper Peer-to-peer communication"
    from_port   = 3888
    to_port     = 3888
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Zookeeper Client access"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Zookeeper Client access via TLS"
    from_port   = 2182
    to_port     = 2182
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Zookeeper Jolokia"
    from_port   = 7770
    to_port     = 7770
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }


  # Kafka Broker
  ingress {
    description = "Kafka Inter-broker listener"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Kafka External listener"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Kafka Confluent Server REST API, Metadata Service (MDS)"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Kafka Jolokia"
    from_port   = 7771
    to_port     = 7771
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # REST Proxy
  ingress {
    description = "Kafka REST Proxy"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # Confluent Control Center *
  ingress {
    description = "Kafka Confluent Control Center"
    from_port   = 9021
    to_port     = 9021
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }


  # Schema Registry
  ingress {
    description = "Schema Registry REST API"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Schema Registry Jolokia"
    from_port   = 7772
    to_port     = 7772
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }


  # Kafka Connect
  ingress {
    description = "Kafka Connect REST API"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Kafka Connect Jolokia"
    from_port   = 7773
    to_port     = 7773
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }


  # ksqlDB
  ingress {
    description = "ksqlDB REST API"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "ksqlDB Jolokia"
    from_port   = 7774
    to_port     = 7774
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }


  ingress {
    description = "JMX"
    from_port = 1099
    to_port = 1099
    protocol = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = [var.internet_cidr_block] 
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name  = "${var.prefix}-confluent-sg"
    Owner = var.owner
  }
}


# Create Database Security Group
resource "aws_security_group" "database_sg" {
  name        = "${var.prefix}_database_sg"
  description = "Security Group for Database Server"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # Oracle
  ingress {
    description = "Oracle Source"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Oracle Target"
    from_port   = 1525
    to_port     = 1525
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # MySQL
  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # Postgres
  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "EDB"
    from_port   = 5444
    to_port     = 5444
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # Elasticsearch
  ingress {
    description = "Elasticsearch"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Kibana"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  # MongoDB
  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name  = "${var.prefix}-database-sg"
    Owner = var.owner
  }
}