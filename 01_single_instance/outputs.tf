output "instance_public_ip" {
  value       = aws_instance.server.public_ip
  description = "Public IP of the AWS instance"
}

output "instance_public_dns" {
  value       = aws_instance.server.public_dns
  description = "Public DNS of the AWS instance"
}