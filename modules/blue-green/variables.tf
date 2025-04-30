# Variables for the blue-green deployment module

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health checks (seconds)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
}

variable "is_green_active" {
  description = "Whether the green environment is active"
  type        = bool
  default     = false
}

variable "deployment_id" {
  description = "Unique identifier for this deployment"
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "List of ARNs to notify when the service health alarm changes state"
  type        = list(string)
  default     = []
}