#!/bin/bash
# Main Validation and Documentation Script
# This script runs both Terraform and YAML validation, and generates documentation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  Terraform & YAML Validation Suite    ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# Get directory to validate
DIR_TO_VALIDATE=${1:-.}
echo -e "Validating templates in: ${DIR_TO_VALIDATE}"

# Make scripts executable
chmod +x "${DIR_TO_VALIDATE}/scripts/validate-terraform.sh"
chmod +x "${DIR_TO_VALIDATE}/scripts/validate-yaml.sh"
chmod +x "${DIR_TO_VALIDATE}/scripts/generate-docs.sh"

# Step 1: Validate Terraform templates
echo -e "\n${YELLOW}Step 1: Validating Terraform templates...${NC}"
if ! "${DIR_TO_VALIDATE}/scripts/validate-terraform.sh" "${DIR_TO_VALIDATE}"; then
    echo -e "${RED}Terraform validation failed. Please fix the issues and try again.${NC}"
    exit 1
else
    echo -e "${GREEN}Terraform validation passed.${NC}"
fi

# Step 2: Validate YAML templates
echo -e "\n${YELLOW}Step 2: Validating YAML templates...${NC}"
if ! "${DIR_TO_VALIDATE}/scripts/validate-yaml.sh" "${DIR_TO_VALIDATE}"; then
    echo -e "${RED}YAML validation failed. Please fix the issues and try again.${NC}"
    exit 1
else
    echo -e "${GREEN}YAML validation passed.${NC}"
fi

# Step 3: Generate documentation
echo -e "\n${YELLOW}Step 3: Generating documentation...${NC}"
if ! "${DIR_TO_VALIDATE}/scripts/generate-docs.sh" "${DIR_TO_VALIDATE}"; then
    echo -e "${RED}Documentation generation failed. Please check the errors and try again.${NC}"
    exit 1
else
    echo -e "${GREEN}Documentation generated successfully.${NC}"
fi

# Print summary
echo -e "\n${YELLOW}=======================================${NC}"
echo -e "${GREEN}All validations passed and documentation generated successfully!${NC}"
echo -e "${YELLOW}=======================================${NC}"

exit 0