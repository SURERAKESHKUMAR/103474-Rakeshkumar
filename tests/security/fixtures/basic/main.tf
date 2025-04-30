# Basic test fixture for security module

provider "aws" {
  region = var.aws_region
}

# Create a VPC for testing
resource "aws_vpc" "test" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

module "security" {
  source = "../../../../modules/security"

  name_prefix         = var.name_prefix
  vpc_id              = aws_vpc.test.id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  container_port      = var.container_port
}