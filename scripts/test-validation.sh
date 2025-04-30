#!/bin/bash
# Test script for validation and documentation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  Testing Validation and Documentation  ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# Get directory to test
DIR_TO_TEST=${1:-.}
echo -e "Testing scripts in: ${DIR_TO_TEST}"

# Make scripts executable
chmod +x "${DIR_TO_TEST}/scripts/validate-terraform.sh"
chmod +x "${DIR_TO_TEST}/scripts/validate-yaml.sh"
chmod +x "${DIR_TO_TEST}/scripts/generate-docs.sh"
chmod +x "${DIR_TO_TEST}/scripts/validate-and-document.sh"

# Test Terraform validation script
echo -e "\n${YELLOW}Testing Terraform validation script...${NC}"
if "${DIR_TO_TEST}/scripts/validate-terraform.sh" "${DIR_TO_TEST}" > /dev/null; then
    echo -e "${GREEN}✓ Terraform validation script works correctly.${NC}"
else
    echo -e "${RED}✗ Terraform validation script failed.${NC}"
    exit 1
fi

# Test YAML validation script
echo -e "\n${YELLOW}Testing YAML validation script...${NC}"
if "${DIR_TO_TEST}/scripts/validate-yaml.sh" "${DIR_TO_TEST}" > /dev/null; then
    echo -e "${GREEN}✓ YAML validation script works correctly.${NC}"
else
    echo -e "${RED}✗ YAML validation script failed.${NC}"
    exit 1
fi

# Test documentation generation script
echo -e "\n${YELLOW}Testing documentation generation script...${NC}"
if "${DIR_TO_TEST}/scripts/generate-docs.sh" "${DIR_TO_TEST}" > /dev/null; then
    echo -e "${GREEN}✓ Documentation generation script works correctly.${NC}"
else
    echo -e "${RED}✗ Documentation generation script failed.${NC}"
    exit 1
fi

# Test main validation and documentation script
echo -e "\n${YELLOW}Testing main validation and documentation script...${NC}"
if "${DIR_TO_TEST}/scripts/validate-and-document.sh" "${DIR_TO_TEST}" > /dev/null; then
    echo -e "${GREEN}✓ Main validation and documentation script works correctly.${NC}"
else
    echo -e "${RED}✗ Main validation and documentation script failed.${NC}"
    exit 1
fi

# Print summary
echo -e "\n${YELLOW}=======================================${NC}"
echo -e "${GREEN}All tests passed!${NC}"
echo -e "${YELLOW}=======================================${NC}"

exit 0