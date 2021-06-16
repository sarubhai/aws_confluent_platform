# Name: confluent.tf
# Owner: Saurav Mitra
# Description: This terraform config will create ELB for Control Center & Kibana

# Control Center ELB
resource "aws_elb" "control_center" {
  name            = "elb-control-center"
  subnets         = var.public_subnet_id
  security_groups = [var.elb_sg_id]

  listener {
    instance_port     = 9021
    instance_protocol = "https"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances = var.control_center_instances_id

  tags = {
    Name  = "${var.prefix}-elb-control-center"
    Owner = var.owner
  }
}

# Kibana ELB
resource "aws_elb" "kibana" {
  name            = "elb-kibana"
  subnets         = var.public_subnet_id
  security_groups = [var.elb_sg_id]

  listener {
    instance_port     = 5601
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances = [var.database_server_id]

  tags = {
    Name  = "${var.prefix}-elb-kibana"
    Owner = var.owner
  }
}
