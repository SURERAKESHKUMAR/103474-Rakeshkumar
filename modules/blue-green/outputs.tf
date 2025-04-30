# Outputs for the blue-green deployment module

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  description = "Name of the blue target group"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  description = "Name of the green target group"
  value       = aws_lb_target_group.green.name
}

output "active_target_group_arn" {
  description = "ARN of the active target group"
  value       = var.is_green_active ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
}

output "inactive_target_group_arn" {
  description = "ARN of the inactive target group"
  value       = var.is_green_active ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "test_listener_arn" {
  description = "ARN of the test listener"
  value       = aws_lb_listener.test.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.service.id
}

output "deployment_id" {
  description = "Unique identifier for this deployment"
  value       = local.deployment_id
}