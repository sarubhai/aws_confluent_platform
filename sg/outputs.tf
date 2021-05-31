# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the Securtiy Group IDs for Ansible Server & Confluent Platform

output "ansible_sg_id" {
  value       = aws_security_group.ansible_sg.id
  description = "Security Group for Ansible Server."
}

output "confluent_sg_id" {
  value       = aws_security_group.confluent_sg.id
  description = "Security Group for Confluent Platform."
}
