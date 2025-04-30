output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = module.ecs.service_id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs.task_definition_arn
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = module.ecs.alb_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.ecs.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.ecs.target_group_arn
}

output "autoscaling_target_id" {
  description = "ID of the Application Auto Scaling target"
  value       = module.ecs.autoscaling_target_id
}