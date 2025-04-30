# Blue-Green Deployment Module for ECS Services
# This module creates the necessary resources for blue-green deployments

locals {
  blue_target_group_name  = "${var.name_prefix}-blue-tg"
  green_target_group_name = "${var.name_prefix}-green-tg"
  deployment_id           = var.deployment_id != "" ? var.deployment_id : formatdate("YYYYMMDDhhmmss", timestamp())
  active_target_group     = var.is_green_active ? local.green_target_group_name : local.blue_target_group_name
  inactive_target_group   = var.is_green_active ? local.blue_target_group_name : local.green_target_group_name
}

# Create blue target group
resource "aws_lb_target_group" "blue" {
  name        = local.blue_target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = "200-299"
  }

  tags = {
    Name        = local.blue_target_group_name
    Environment = var.environment
    Deployment  = "blue"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create green target group
resource "aws_lb_target_group" "green" {
  name        = local.green_target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = "200-299"
  }

  tags = {
    Name        = local.green_target_group_name
    Environment = var.environment
    Deployment  = "green"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create ALB listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = var.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.is_green_active ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Create test listener for the inactive environment
resource "aws_lb_listener" "test" {
  load_balancer_arn = var.alb_arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.is_green_active ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }
}

# Create ECS service for the active environment
resource "aws_ecs_service" "service" {
  name            = "${var.name_prefix}-service-${local.deployment_id}"
  cluster         = var.ecs_cluster_id
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.is_green_active ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [task_definition]
  }

  depends_on = [aws_lb_listener.http]
}

# CloudWatch alarm for service health
resource "aws_cloudwatch_metric_alarm" "service_health" {
  alarm_name          = "${var.name_prefix}-service-health-${local.deployment_id}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors the health of the ECS service"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.is_green_active ? aws_lb_target_group.green.arn_suffix : aws_lb_target_group.blue.arn_suffix
  }

  tags = {
    Name        = "${var.name_prefix}-service-health-alarm"
    Environment = var.environment
    Deployment  = var.is_green_active ? "green" : "blue"
  }
}