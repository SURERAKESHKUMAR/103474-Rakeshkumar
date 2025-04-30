output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "cpu_utilization_alarm_arn" {
  description = "ARN of the CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_utilization.arn
}

output "memory_utilization_alarm_arn" {
  description = "ARN of the memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.memory_utilization.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = var.alarm_email != "" ? aws_sns_topic.alarms[0].arn : ""
}