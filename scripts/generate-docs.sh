#!/bin/bash
# Documentation Generation Script
# This script generates comprehensive documentation for Terraform and YAML templates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}    Documentation Generation Tool       ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# Check if python is installed
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo -e "${RED}Error: Python is not installed. Please install Python first.${NC}"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

# Check if terraform-docs is installed
if ! command -v terraform-docs &> /dev/null; then
    echo -e "${YELLOW}Warning: terraform-docs is not installed. Will use basic documentation generation.${NC}"
    echo -e "${YELLOW}To install terraform-docs, visit: https://github.com/terraform-docs/terraform-docs${NC}"
    SKIP_TERRAFORM_DOCS=true
fi

# Get directory to document
DIR_TO_DOCUMENT=${1:-.}
echo -e "Generating documentation for: ${DIR_TO_DOCUMENT}"

# Create docs directory if it doesn't exist
DOCS_DIR="${DIR_TO_DOCUMENT}/docs"
mkdir -p "$DOCS_DIR"

# Step 1: Generate main README
echo -e "\n${YELLOW}Step 1: Generating main README...${NC}"

# Extract project name from variables.tf
PROJECT_NAME=$(grep -A 2 'variable "project"' "${DIR_TO_DOCUMENT}/variables.tf" | grep 'default' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="Terraform ECS Infrastructure"
fi

cat > "${DOCS_DIR}/README.md" << EOF
# ${PROJECT_NAME} Documentation

This documentation is automatically generated from the Terraform and YAML templates in this repository.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Infrastructure Components](#infrastructure-components)
3. [Module Documentation](#module-documentation)
4. [Pipeline Documentation](#pipeline-documentation)
5. [Variables Reference](#variables-reference)
6. [Outputs Reference](#outputs-reference)
7. [Deployment Guide](#deployment-guide)

## Project Overview

This repository contains Terraform configurations to deploy an Amazon ECS (Elastic Container Service) infrastructure following AWS best practices and the Well-Architected Framework.

### Repository Structure

\`\`\`
$(find ${DIR_TO_DOCUMENT} -type f -not -path "*/\.*" -not -path "*/docs/*" | sort | sed 's|'${DIR_TO_DOCUMENT}'/||')
\`\`\`

### Features

- **Modularity**: Organized into reusable modules for better maintainability
- **Security**: Follows security best practices for IAM, security groups, and sensitive data
- **High Availability**: Multi-AZ deployment for fault tolerance
- **Auto Scaling**: Dynamic scaling based on demand
- **Right-Sizing**: Optimized resource allocation
- **Monitoring**: CloudWatch integration for observability
- **Tagging**: Comprehensive resource tagging for better management
- **CI/CD Pipeline**: Automated build, test, and deployment with quality gates
- **Blue-Green Deployment**: Zero-downtime deployment strategy

## Infrastructure Components

The infrastructure consists of the following main components:

EOF

# Step 2: Generate module documentation
echo -e "\n${YELLOW}Step 2: Generating module documentation...${NC}"

mkdir -p "${DOCS_DIR}/modules"

# Find all module directories
MODULE_DIRS=$(find "${DIR_TO_DOCUMENT}/modules" -type d -mindepth 1 -maxdepth 1)

for module_dir in $MODULE_DIRS; do
    module_name=$(basename "$module_dir")
    echo -e "Generating documentation for module: ${module_name}"
    
    if [ -z "$SKIP_TERRAFORM_DOCS" ]; then
        # Use terraform-docs to generate module documentation
        terraform-docs markdown table "$module_dir" > "${DOCS_DIR}/modules/${module_name}.md"
    else
        # Basic documentation generation
        cat > "${DOCS_DIR}/modules/${module_name}.md" << EOF
# ${module_name} Module

## Overview

$(grep -A 2 "# ${module_name} module" "${module_dir}/main.tf" 2>/dev/null || echo "This module provides ${module_name} functionality.")

## Files

\`\`\`
$(find "${module_dir}" -type f | sort | sed 's|'${module_dir}'/||')
\`\`\`

## Variables

$(grep -A 3 "variable" "${module_dir}"/*.tf 2>/dev/null | sed 's/variable "/- **/' | sed 's/".*{/**: /' | sed 's/description *= *"//' | sed 's/".*//' | grep -v -E "^[[:space:]]*$" | grep -v -E "^--$" || echo "No variables found.")

## Outputs

$(grep -A 2 "output" "${module_dir}"/*.tf 2>/dev/null | sed 's/output "/- **/' | sed 's/".*{/**: /' | sed 's/description *= *"//' | sed 's/".*//' | grep -v -E "^[[:space:]]*$" | grep -v -E "^--$" || echo "No outputs found.")
EOF
    fi
    
    # Add module to main README
    cat >> "${DOCS_DIR}/README.md" << EOF
### ${module_name} Module

$(head -n 5 "${DOCS_DIR}/modules/${module_name}.md" | tail -n 3)

[Detailed ${module_name} Module Documentation](modules/${module_name}.md)

EOF
done

# Step 3: Generate pipeline documentation
echo -e "\n${YELLOW}Step 3: Generating pipeline documentation...${NC}"

mkdir -p "${DOCS_DIR}/pipelines"

# Document Azure DevOps pipeline
cat > "${DOCS_DIR}/pipelines/azure-devops.md" << EOF
# Azure DevOps Pipeline Documentation

## Overview

This repository includes Azure DevOps pipeline templates for CI/CD automation of the Terraform infrastructure.

## Pipeline Files

- **terraform-pipeline.yml**: Main pipeline template
- **terraform-plan-steps.yml**: Steps for terraform plan
- **terraform-apply-steps.yml**: Steps for terraform apply

## Pipeline Structure

The pipeline consists of the following stages:

1. **Validate**: Performs syntax and security checks on Terraform code
2. **Code Quality**: Runs SonarQube and Snyk scans
3. **Plan**: Generates Terraform plans for each environment
4. **Deploy**: Applies Terraform changes to each environment with appropriate approvals

## Configuration

### Variable Groups

The pipeline requires the following variable groups:

- **terraform-secrets**: AWS credentials
- **sonarqube-config**: SonarQube connection details
- **snyk-config**: Snyk API token
- **slack-webhook**: Slack webhook URL

### Service Connections

- AWS service connections for each environment

## Blue-Green Deployment

For production deployments, the pipeline supports blue-green deployment strategy:

1. Deploy new version alongside existing version
2. Validate new deployment
3. Switch traffic to new version
4. Terminate old version after approval

## Pipeline Parameters

$(grep -A 3 "name:" "${DIR_TO_DOCUMENT}/pipeline-templates/terraform-pipeline.yml" | grep -v -E "^--$" | sed 's/    name: /- **/' | sed 's/$/**: /' | sed 's/    default: //' | grep -v -E "^[[:space:]]*$" || echo "No parameters found.")
EOF

# Add pipeline documentation to main README
cat >> "${DOCS_DIR}/README.md" << EOF
## Pipeline Documentation

This repository includes CI/CD pipeline templates for automating the deployment of the infrastructure.

[Azure DevOps Pipeline Documentation](pipelines/azure-devops.md)

EOF

# Step 4: Generate variables reference
echo -e "\n${YELLOW}Step 4: Generating variables reference...${NC}"

cat > "${DOCS_DIR}/variables.md" << EOF
# Variables Reference

This document provides a reference for all input variables used in this Terraform configuration.

## Root Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
$(grep -A 4 "variable" "${DIR_TO_DOCUMENT}/variables.tf" | awk 'BEGIN{RS="variable"; FS="\n"} NR>1 {gsub(/["{}/]/, "", $1); name=$1; desc=""; type=""; def=""; for(i=1; i<=NF; i++) {if($i ~ /description/) {gsub(/description *= *"/, "", $i); gsub(/"/, "", $i); desc=$i} if($i ~ /type/) {gsub(/type *= */, "", $i); type=$i} if($i ~ /default/) {gsub(/default *= */, "", $i); def=$i}} if(def=="") {req="yes"} else {req="no"}; if(name!="") printf "| %s | %s | %s | %s | %s |\n", name, desc, type, def, req}')
EOF

# Add variables reference to main README
cat >> "${DOCS_DIR}/README.md" << EOF
## Variables Reference

This repository uses the following input variables to configure the infrastructure.

[Complete Variables Reference](variables.md)

EOF

# Step 5: Generate outputs reference
echo -e "\n${YELLOW}Step 5: Generating outputs reference...${NC}"

cat > "${DOCS_DIR}/outputs.md" << EOF
# Outputs Reference

This document provides a reference for all outputs from this Terraform configuration.

## Root Outputs

| Name | Description |
|------|-------------|
$(grep -A 2 "output" "${DIR_TO_DOCUMENT}/outputs.tf" 2>/dev/null | awk 'BEGIN{RS="output"; FS="\n"} NR>1 {gsub(/["{}/]/, "", $1); name=$1; desc=""; for(i=1; i<=NF; i++) {if($i ~ /description/) {gsub(/description *= *"/, "", $i); gsub(/"/, "", $i); desc=$i}} if(name!="") printf "| %s | %s |\n", name, desc}' || echo "No outputs found.")
EOF

# Add outputs reference to main README
cat >> "${DOCS_DIR}/README.md" << EOF
## Outputs Reference

This Terraform configuration produces the following outputs.

[Complete Outputs Reference](outputs.md)

EOF

# Step 6: Generate deployment guide
echo -e "\n${YELLOW}Step 6: Generating deployment guide...${NC}"

cat > "${DOCS_DIR}/deployment-guide.md" << EOF
# Deployment Guide

This guide provides step-by-step instructions for deploying the infrastructure using this Terraform configuration.

## Prerequisites

- Terraform v1.0.0+
- AWS CLI configured with appropriate permissions
- An AWS account with access to create the required resources
- Azure DevOps for CI/CD pipeline (or adapt templates for GitHub Actions/GitLab CI)

## Local Deployment

### 1. Clone the Repository

\`\`\`bash
git clone <repository-url>
cd <repository-directory>
\`\`\`

### 2. Configure Variables

Create a \`terraform.tfvars\` file with your configuration:

\`\`\`hcl
# General
environment = "dev"
project     = "${PROJECT_NAME}"
aws_region  = "us-west-2"

# Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]

# ECS
container_image = "nginx:latest"
container_port  = 80
desired_count   = 2

# Add other variables as needed
\`\`\`

### 3. Initialize Terraform

\`\`\`bash
terraform init
\`\`\`

### 4. Plan the Deployment

\`\`\`bash
terraform plan -out=tfplan
\`\`\`

### 5. Apply the Configuration

\`\`\`bash
terraform apply tfplan
\`\`\`

### 6. Verify the Deployment

After the deployment completes, verify that all resources were created correctly:

\`\`\`bash
terraform output
\`\`\`

## CI/CD Deployment

### Azure DevOps Pipeline

1. Import the pipeline templates into your Azure DevOps project
2. Configure the required variable groups:
   - \`terraform-secrets\`: AWS credentials
   - \`sonarqube-config\`: SonarQube connection details
   - \`snyk-config\`: Snyk API token
   - \`slack-webhook\`: Slack webhook URL
3. Set up service connections for AWS environments
4. Create an S3 bucket for Terraform state storage
5. Run the pipeline

## Cleanup

To destroy the infrastructure when no longer needed:

\`\`\`bash
terraform destroy
\`\`\`
EOF

# Add deployment guide to main README
cat >> "${DOCS_DIR}/README.md" << EOF
## Deployment Guide

For detailed instructions on how to deploy this infrastructure, see the [Deployment Guide](deployment-guide.md).
EOF

# Print summary
echo -e "\n${GREEN}Documentation generated successfully in ${DOCS_DIR}${NC}"
echo -e "Generated files:"
find "$DOCS_DIR" -type f | sort

exit 0