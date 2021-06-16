# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the ELB URL's


output "control_center_url" {
  value = aws_elb.control_center.dns_name
  description = "Control Center URL."
}

output "kibana_url" {
  value = aws_elb.kibana.dns_name
  description = "Kibana URL."
}