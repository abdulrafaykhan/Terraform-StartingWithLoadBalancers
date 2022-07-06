output "lb_dns_name" {
  description = "DNS Name of the created LoadBalancer"
  value       = aws_lb.external_lb.dns_name
}