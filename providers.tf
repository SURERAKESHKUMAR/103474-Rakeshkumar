terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment to use Terraform Cloud/Enterprise for state management
  # backend "remote" {
  #   organization = "your-org-name"
  #   workspaces {
  #     name = "your-workspace-name"
  #   }
  # }
}

provider "aws" {
  region = var.aws_region
  
  # Default tags applied to all resources
  default_tags {
    tags = var.default_tags
  }
}