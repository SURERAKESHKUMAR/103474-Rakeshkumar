# Monitoring module - Creates CloudWatch log groups, alarms, and dashboards

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}/${var.container_name}"
  retention_in_days = 30

  tags = {
    Name        = "/ecs/${var.name_prefix}/${var.container_name}"
    Environment = var.name_prefix
  }
}

# CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.name_prefix}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  ok_actions          = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name = "${var.name_prefix}-cpu-utilization-alarm"
  }
}

# CloudWatch Alarm for Memory Utilization
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "${var.name_prefix}-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  ok_actions          = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name = "${var.name_prefix}-memory-utilization-alarm"
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  count = var.alarm_email != "" ? 1 : 0
  name  = "${var.name_prefix}-alarms"

  tags = {
    Name = "${var.name_prefix}-alarms"
  }
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Get current AWS region
data "aws_region" "current" {}