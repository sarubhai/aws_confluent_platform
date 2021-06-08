# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the Securtiy Group IDs for Ansible Server, Confluent Platform & Demo Database Server

output "ansible_sg_id" {
  value       = aws_security_group.ansible_sg.id
  description = "Security Group for Ansible Server."
}

output "confluent_sg_id" {
  value       = aws_security_group.confluent_sg.id
  description = "Security Group for Confluent Platform."
}

output "database_sg_id" {
  value       = aws_security_group.database_sg.id
  description = "Security Group for Database Server."
}