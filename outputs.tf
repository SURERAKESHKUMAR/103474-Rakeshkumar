# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = module.ecs.service_id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs.task_definition_arn
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.ecs.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.ecs.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = module.ecs.alb_arn
}

# Security Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.security.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.security.ecs_task_role_arn
}

# Monitoring Outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.monitoring.log_group_name
}

output "cpu_utilization_alarm_arn" {
  description = "ARN of the CPU utilization alarm"
  value       = module.monitoring.cpu_utilization_alarm_arn
}

output "memory_utilization_alarm_arn" {
  description = "ARN of the memory utilization alarm"
  value       = module.monitoring.memory_utilization_alarm_arn
}