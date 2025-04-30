# Terraform ECS Infrastructure

This repository contains Terraform configurations to deploy an Amazon ECS (Elastic Container Service) infrastructure following AWS best practices and the Well-Architected Framework.

## Project Structure

```
.
├── main.tf           # Main configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── providers.tf      # Provider configuration
├── terraform.tfvars.example # Example variable values (not actual secrets)
├── modules/          # Reusable modules
│   ├── networking/   # VPC, subnets, etc.
│   ├── security/     # Security groups, IAM roles
│   ├── ecs/          # ECS cluster, service, task definition
│   ├── monitoring/   # CloudWatch alarms and dashboards
│   └── blue-green/   # Blue-green deployment resources
├── pipeline-templates/ # CI/CD pipeline templates
│   ├── terraform-pipeline.yml        # Main pipeline template
│   ├── terraform-plan-steps.yml      # Steps for terraform plan
│   └── terraform-apply-steps.yml     # Steps for terraform apply
└── README.md         # Documentation
```

## Features

- **Modularity**: Organized into reusable modules for better maintainability
- **Security**: Follows security best practices for IAM, security groups, and sensitive data
- **High Availability**: Multi-AZ deployment for fault tolerance
- **Auto Scaling**: Dynamic scaling based on demand
- **Right-Sizing**: Optimized resource allocation
- **Monitoring**: CloudWatch integration for observability
- **Tagging**: Comprehensive resource tagging for better management
- **CI/CD Pipeline**: Automated build, test, and deployment with quality gates
- **Blue-Green Deployment**: Zero-downtime deployment strategy

## Prerequisites

- Terraform v1.0.0+
- AWS CLI configured with appropriate permissions
- An AWS account with access to create the required resources
- Azure DevOps for CI/CD pipeline (or adapt templates for GitHub Actions/GitLab CI)

## Usage

### Local Development

1. Clone this repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values
3. Initialize Terraform: `terraform init`
4. Plan the deployment: `terraform plan`
5. Apply the configuration: `terraform apply`

### CI/CD Pipeline Options

This repository includes pipeline templates for both Azure DevOps and GitHub Actions:

### Azure DevOps Pipeline

The Azure DevOps pipeline templates are located in the `pipeline-templates` directory:
- `terraform-pipeline.yml`: Main pipeline template
- `terraform-plan-steps.yml`: Steps for terraform plan
- `terraform-apply-steps.yml`: Steps for terraform apply

To use the Azure DevOps pipeline:
1. Import the pipeline templates into your Azure DevOps project
2. Configure the required variable groups:
   - `terraform-secrets`: AWS credentials
   - `sonarqube-config`: SonarQube connection details
   - `snyk-config`: Snyk API token
   - `slack-webhook`: Slack webhook URL
3. Set up service connections for AWS environments
4. Create an S3 bucket for Terraform state storage
5. Run the pipeline

### GitHub Actions Workflow

The GitHub Actions workflow files are located in the `.github/workflows` directory:
- `terraform-pipeline.yml`: Main CI pipeline for validation and testing
- `terraform-pipeline-deploy.yml`: Deployment pipeline for different environments

To use the GitHub Actions workflow:
1. Configure the required GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`: AWS access key
   - `AWS_SECRET_ACCESS_KEY`: AWS secret key
   - `SONAR_TOKEN`: SonarQube token
   - `SONAR_HOST_URL`: SonarQube URL
   - `SNYK_TOKEN`: Snyk API token
   - `SLACK_WEBHOOK_URL`: Slack webhook URL
2. Set up GitHub Environments with protection rules:
   - `dev`: Development environment
   - `staging`: Staging environment
   - `production`: Production environment with required reviewers
3. Create an S3 bucket for Terraform state storage
4. Push to the main branch to trigger the workflow

## AWS Well-Architected Framework Alignment

- **Operational Excellence**: Infrastructure as code, comprehensive documentation, CI/CD automation
- **Security**: Least privilege access, network isolation, encryption, security scanning
- **Reliability**: Multi-AZ deployment, auto-recovery, blue-green deployments
- **Performance Efficiency**: Right-sized resources, auto-scaling
- **Cost Optimization**: Appropriate instance types, scaling policies

## Validation and Documentation

This repository includes scripts for validating Terraform and YAML templates, and generating comprehensive documentation:

### Validation Scripts

- **validate-terraform.sh**: Validates Terraform templates for syntax errors, formatting issues, and best practices
- **validate-yaml.sh**: Validates YAML templates for syntax errors and best practices
- **validate-and-document.sh**: Main script that runs both validations and generates documentation

To run the validation and documentation scripts:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the main validation and documentation script
./scripts/validate-and-document.sh
```

### Documentation Generation

The documentation generation script (`generate-docs.sh`) creates comprehensive documentation for the infrastructure:

- **Module Documentation**: Detailed documentation for each Terraform module
- **Pipeline Documentation**: Documentation for the CI/CD pipeline
- **Variables Reference**: Reference for all input variables
- **Outputs Reference**: Reference for all outputs
- **Deployment Guide**: Step-by-step instructions for deploying the infrastructure

The generated documentation is stored in the `docs` directory.

## Pipeline Features

### Validation Stage
- Terraform format and validation checks
- TFLint for Terraform linting
- TFSec for security scanning
- Checkov for compliance scanning

### Code Quality Stage
- SonarQube analysis for code quality
- Snyk security scanning

### Plan Stage
- Terraform plan for each environment
- Plan summary published as artifacts
- Plan comments on pull requests

### Deploy Stages
- Separate deployment stage for each environment
- Approval gates for staging and production
- Blue-green deployment for production
- Slack notifications for deployment events
