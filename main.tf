# Main Terraform configuration file for ECS infrastructure

locals {
  name_prefix = "${var.project}-${var.environment}"
  ecs_cluster_name = "${local.name_prefix}-${var.ecs_cluster_name}"
  ecs_service_name = "${local.name_prefix}-${var.ecs_service_name}"
}

# Networking module - Creates VPC, subnets, route tables, internet gateway, NAT gateway
module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  name_prefix          = local.name_prefix
}

# Security module - Creates security groups, IAM roles and policies
module "security" {
  source = "./modules/security"

  name_prefix         = local.name_prefix
  vpc_id              = module.networking.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  container_port      = var.container_port
}

# Monitoring module - Creates CloudWatch log groups
# This needs to be created before the ECS module to avoid circular dependencies
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix               = local.name_prefix
  ecs_cluster_name          = local.ecs_cluster_name
  ecs_service_name          = local.ecs_service_name
  container_name            = var.container_name
  enable_enhanced_monitoring = var.enable_enhanced_monitoring
  alarm_email               = var.alarm_email
}

# ECS module - Creates ECS cluster, service, task definition, load balancer
module "ecs" {
  source = "./modules/ecs"

  name_prefix                = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  private_subnet_ids         = module.networking.private_subnet_ids
  ecs_cluster_name           = local.ecs_cluster_name
  ecs_service_name           = local.ecs_service_name
  container_name             = var.container_name
  container_image            = var.container_image
  container_port             = var.container_port
  container_cpu              = var.container_cpu
  container_memory           = var.container_memory
  desired_count              = var.desired_count
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn          = module.security.ecs_task_role_arn
  alb_security_group_id      = module.security.alb_security_group_id
  ecs_security_group_id      = module.security.ecs_security_group_id
  health_check_path          = var.health_check_path
  health_check_interval      = var.health_check_interval
  health_check_timeout       = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  log_group_name             = module.monitoring.log_group_name
  
  # Auto scaling configuration
  enable_autoscaling   = var.enable_autoscaling
  min_capacity         = var.min_capacity
  max_capacity         = var.max_capacity
  cpu_target_value     = var.cpu_target_value
  memory_target_value  = var.memory_target_value
}

# Update monitoring module with load balancer information after ECS creation
resource "aws_cloudwatch_metric_alarm" "service_health" {
  alarm_name          = "${local.name_prefix}-service-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors the health of the ECS service"
  alarm_actions       = var.alarm_email != "" ? [module.monitoring.sns_topic_arn] : []
  ok_actions          = var.alarm_email != "" ? [module.monitoring.sns_topic_arn] : []

  dimensions = {
    LoadBalancer = split("/", module.ecs.alb_arn)[1]
    TargetGroup  = split("/", module.ecs.target_group_arn)[1]
  }

  tags = {
    Name = "${local.name_prefix}-service-health-alarm"
  }
}

# CloudWatch Dashboard for ECS
resource "aws_cloudwatch_dashboard" "ecs" {
  count          = var.enable_enhanced_monitoring ? 1 : 0
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", local.ecs_service_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", local.ecs_service_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", split("/", module.ecs.alb_arn)[1]]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Request Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", split("/", module.ecs.alb_arn)[1]]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Response Time"
        }
      }
    ]
  })
}

# Get current AWS region
data "aws_region" "current" {}