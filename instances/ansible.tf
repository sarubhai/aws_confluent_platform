# Name: ansible.tf
# Owner: Saurav Mitra
# Description: This terraform config will create a EC2 instance for Ansible Server


# Ansible AMI Filter
data "aws_ami" "ansible_centos" {
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


# User Data Init
data "template_file" "init" {
  template = templatefile("${path.module}/ansible_server.sh", {
    keypair_name        = var.keypair_name
    zookeeper_pvt       = aws_instance.zookeeper[*].private_dns
    zookeeper_pub       = aws_instance.zookeeper[*].public_dns
    kafka_broker_pvt    = aws_instance.kafka_broker[*].private_dns
    kafka_broker_pub    = aws_instance.kafka_broker[*].public_dns
    rest_proxy_pvt      = aws_instance.rest_proxy[*].private_dns
    rest_proxy_pub      = aws_instance.rest_proxy[*].public_dns
    control_center_pvt  = aws_instance.control_center[*].private_dns
    control_center_pub  = aws_instance.control_center[*].public_dns
    schema_registry_pvt = aws_instance.schema_registry[*].private_dns
    schema_registry_pub = aws_instance.schema_registry[*].public_dns
    kafka_connect_pvt   = aws_instance.kafka_connect[*].private_dns
    kafka_connect_pub   = aws_instance.kafka_connect[*].public_dns
    ksql_pvt            = aws_instance.ksql[*].private_dns
    ksql_pub            = aws_instance.ksql[*].public_dns
  })
}


# EC2 Instance
resource "aws_instance" "ansible-server" {
  ami                         = data.aws_ami.ansible_centos.id
  instance_type               = var.ansible_instance_type
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_id[0]
  vpc_security_group_ids      = [var.ansible_sg_id]
  key_name                    = var.keypair_name
  source_dest_check           = false

  root_block_device {
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-ansible-server"
    Owner = var.owner
  }

  user_data = data.template_file.init.rendered
  
  connection {
    type     = "ssh"
    user     = "centos"
    private_key = file("${path.module}/${var.keypair_name}.pem")
    host     = self.public_ip
  }
  
  provisioner "file" {
    source      = "${path.module}/${var.keypair_name}.pem"
    destination = "/home/centos/.ssh/${var.keypair_name}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/centos/.ssh/${var.keypair_name}.pem"
    ]
  }
}
