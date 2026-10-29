output "public_ip" {
  description = "Public IPv4 address of the app instance."
  value       = aws_instance.app.public_ip
}

output "app_port" {
  description = "TCP port on which intern-task-app listens."
  value       = local.app_port
}