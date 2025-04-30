#!/bin/bash
# Terraform Validation Script
# This script validates Terraform templates for syntax errors, formatting issues, and best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}   Terraform Template Validation Tool   ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed. Please install Terraform first.${NC}"
    exit 1
fi

# Check if tflint is installed
if ! command -v tflint &> /dev/null; then
    echo -e "${YELLOW}Warning: TFLint is not installed. Skipping TFLint checks.${NC}"
    echo -e "${YELLOW}To install TFLint, visit: https://github.com/terraform-linters/tflint${NC}"
    SKIP_TFLINT=true
fi

# Check if tfsec is installed
if ! command -v tfsec &> /dev/null; then
    echo -e "${YELLOW}Warning: TFSec is not installed. Skipping security checks.${NC}"
    echo -e "${YELLOW}To install TFSec, visit: https://github.com/aquasecurity/tfsec${NC}"
    SKIP_TFSEC=true
fi

# Check if checkov is installed
if ! command -v checkov &> /dev/null; then
    echo -e "${YELLOW}Warning: Checkov is not installed. Skipping compliance checks.${NC}"
    echo -e "${YELLOW}To install Checkov, run: pip install checkov${NC}"
    SKIP_CHECKOV=true
fi

# Get directory to validate
DIR_TO_VALIDATE=${1:-.}
echo -e "Validating Terraform templates in: ${DIR_TO_VALIDATE}"

# Count errors
ERRORS=0
WARNINGS=0

# Step 1: Check Terraform formatting
echo -e "\n${YELLOW}Step 1: Checking Terraform formatting...${NC}"
if ! terraform fmt -check -recursive "${DIR_TO_VALIDATE}"; then
    echo -e "${RED}Error: Terraform formatting issues found.${NC}"
    echo -e "${YELLOW}Run 'terraform fmt -recursive' to fix formatting issues.${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "${GREEN}✓ Terraform formatting is correct.${NC}"
fi

# Step 2: Initialize Terraform (without backend)
echo -e "\n${YELLOW}Step 2: Initializing Terraform...${NC}"
if ! terraform -chdir="${DIR_TO_VALIDATE}" init -backend=false -input=false > /dev/null; then
    echo -e "${RED}Error: Terraform initialization failed.${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "${GREEN}✓ Terraform initialized successfully.${NC}"
fi

# Step 3: Validate Terraform configuration
echo -e "\n${YELLOW}Step 3: Validating Terraform configuration...${NC}"
if ! terraform -chdir="${DIR_TO_VALIDATE}" validate; then
    echo -e "${RED}Error: Terraform validation failed.${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "${GREEN}✓ Terraform configuration is valid.${NC}"
fi

# Step 4: Run TFLint for additional linting
if [ -z "$SKIP_TFLINT" ]; then
    echo -e "\n${YELLOW}Step 4: Running TFLint for additional linting...${NC}"
    if ! tflint --init > /dev/null && tflint --recursive "${DIR_TO_VALIDATE}"; then
        echo -e "${RED}Error: TFLint found issues.${NC}"
        WARNINGS=$((WARNINGS+1))
    else
        echo -e "${GREEN}✓ TFLint passed.${NC}"
    fi
else
    echo -e "\n${YELLOW}Step 4: Skipping TFLint checks.${NC}"
fi

# Step 5: Run TFSec for security checks
if [ -z "$SKIP_TFSEC" ]; then
    echo -e "\n${YELLOW}Step 5: Running TFSec for security checks...${NC}"
    if ! tfsec "${DIR_TO_VALIDATE}" --no-color; then
        echo -e "${RED}Warning: TFSec found security issues.${NC}"
        WARNINGS=$((WARNINGS+1))
    else
        echo -e "${GREEN}✓ TFSec security checks passed.${NC}"
    fi
else
    echo -e "\n${YELLOW}Step 5: Skipping TFSec security checks.${NC}"
fi

# Step 6: Run Checkov for compliance checks
if [ -z "$SKIP_CHECKOV" ]; then
    echo -e "\n${YELLOW}Step 6: Running Checkov for compliance checks...${NC}"
    if ! checkov -d "${DIR_TO_VALIDATE}" --quiet; then
        echo -e "${RED}Warning: Checkov found compliance issues.${NC}"
        WARNINGS=$((WARNINGS+1))
    else
        echo -e "${GREEN}✓ Checkov compliance checks passed.${NC}"
    fi
else
    echo -e "\n${YELLOW}Step 6: Skipping Checkov compliance checks.${NC}"
fi

# Step 7: Check for hardcoded secrets
echo -e "\n${YELLOW}Step 7: Checking for hardcoded secrets...${NC}"
if grep -r -E "(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|password|secret|token|key).*=.*[A-Za-z0-9/\+]{8,}" --include="*.tf" "${DIR_TO_VALIDATE}"; then
    echo -e "${RED}Warning: Potential hardcoded secrets found. Please review the above files.${NC}"
    WARNINGS=$((WARNINGS+1))
else
    echo -e "${GREEN}✓ No hardcoded secrets found.${NC}"
fi

# Step 8: Check for required tags
echo -e "\n${YELLOW}Step 8: Checking for required tags...${NC}"
if ! grep -r "tags" --include="*.tf" "${DIR_TO_VALIDATE}" | grep -i -E "(environment|name|project|managedby)" > /dev/null; then
    echo -e "${YELLOW}Warning: Some resources might be missing required tags (environment, name, project, managedby).${NC}"
    WARNINGS=$((WARNINGS+1))
else
    echo -e "${GREEN}✓ Required tags found.${NC}"
fi

# Print summary
echo -e "\n${YELLOW}=======================================${NC}"
echo -e "${YELLOW}              Summary                  ${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo -e "Errors: ${ERRORS}"
echo -e "Warnings: ${WARNINGS}"

if [ $ERRORS -gt 0 ]; then
    echo -e "\n${RED}Validation failed with ${ERRORS} errors and ${WARNINGS} warnings.${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "\n${YELLOW}Validation completed with ${WARNINGS} warnings.${NC}"
    exit 0
else
    echo -e "\n${GREEN}Validation completed successfully with no errors or warnings.${NC}"
    exit 0
fi