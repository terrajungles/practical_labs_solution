output "alb_public_dns" {
  value       = aws_lb.server_alb.dns_name
  description = "DNS Name of the Application Load Balancer"
}