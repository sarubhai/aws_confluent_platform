# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the Securtiy Group IDs for Ansible Server, Confluent Platform & Demo Database Server

output "ansible_sg_id" {
  value       = aws_security_group.ansible_sg.id
  description = "Security Group for Ansible Server."
}

output "zookeeper_sg_id" {
  value       = aws_security_group.zookeeper_sg.id
  description = "Security Group for Zookeeper."
}

output "kafka_sg_id" {
  value       = aws_security_group.kafka_sg.id
  description = "Security Group for Kafka."
}

output "rest_proxy_sg_id" {
  value       = aws_security_group.rest_proxy_sg.id
  description = "Security Group for REST Proxy."
}

output "control_center_sg_id" {
  value       = aws_security_group.control_center_sg.id
  description = "Security Group for Control Center."
}

output "schema_registry_sg_id" {
  value       = aws_security_group.schema_registry_sg.id
  description = "Security Group for Schema Registry."
}

output "kafka_connect_sg_id" {
  value       = aws_security_group.kafka_connect_sg.id
  description = "Security Group for Kafka Connect."
}

output "ksql_sg_id" {
  value       = aws_security_group.ksql_sg.id
  description = "Security Group for KSQL."
}

output "database_sg_id" {
  value       = aws_security_group.database_sg.id
  description = "Security Group for Database Server."
}
