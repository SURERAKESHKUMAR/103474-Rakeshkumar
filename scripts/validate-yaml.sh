#!/bin/bash
# YAML Validation Script
# This script validates YAML templates for syntax errors and best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}      YAML Template Validation Tool     ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# Check if yamllint is installed
if ! command -v yamllint &> /dev/null; then
    echo -e "${YELLOW}Warning: yamllint is not installed. Will use basic validation only.${NC}"
    echo -e "${YELLOW}To install yamllint, run: pip install yamllint${NC}"
    SKIP_YAMLLINT=true
fi

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

# Get directory to validate
DIR_TO_VALIDATE=${1:-.}
echo -e "Validating YAML templates in: ${DIR_TO_VALIDATE}"

# Count errors
ERRORS=0
WARNINGS=0

# Create a temporary Python script for YAML validation
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" << 'EOF'
import sys
import yaml
import os
import re

def validate_yaml_file(file_path):
    try:
        with open(file_path, 'r') as file:
            yaml.safe_load(file)
        return True, None
    except yaml.YAMLError as e:
        return False, str(e)
    except Exception as e:
        return False, str(e)

if __name__ == "__main__":
    file_path = sys.argv[1]
    valid, error = validate_yaml_file(file_path)
    if not valid:
        print(f"Error in {file_path}: {error}")
        sys.exit(1)
    sys.exit(0)
EOF

# Step 1: Find all YAML files
echo -e "\n${YELLOW}Step 1: Finding YAML files...${NC}"
YAML_FILES=$(find "${DIR_TO_VALIDATE}" -type f -name "*.yml" -o -name "*.yaml")
YAML_COUNT=$(echo "$YAML_FILES" | wc -l)

if [ -z "$YAML_FILES" ]; then
    echo -e "${YELLOW}No YAML files found in ${DIR_TO_VALIDATE}${NC}"
    exit 0
else
    echo -e "${GREEN}Found ${YAML_COUNT} YAML files.${NC}"
fi

# Step 2: Basic YAML syntax validation
echo -e "\n${YELLOW}Step 2: Validating YAML syntax...${NC}"
INVALID_FILES=0

for file in $YAML_FILES; do
    if ! $PYTHON_CMD "$TMP_SCRIPT" "$file"; then
        INVALID_FILES=$((INVALID_FILES+1))
        ERRORS=$((ERRORS+1))
    fi
done

if [ $INVALID_FILES -eq 0 ]; then
    echo -e "${GREEN}✓ All YAML files have valid syntax.${NC}"
else
    echo -e "${RED}Error: ${INVALID_FILES} files have invalid YAML syntax.${NC}"
fi

# Step 3: Run yamllint for additional linting
if [ -z "$SKIP_YAMLLINT" ]; then
    echo -e "\n${YELLOW}Step 3: Running yamllint for additional linting...${NC}"
    
    # Create a temporary yamllint config file
    YAMLLINT_CONFIG=$(mktemp)
    cat > "$YAMLLINT_CONFIG" << 'EOF'
extends: default

rules:
  line-length: disable
  document-start: disable
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no', 'on', 'off']
EOF
    
    YAMLLINT_ISSUES=0
    for file in $YAML_FILES; do
        if ! yamllint -c "$YAMLLINT_CONFIG" "$file"; then
            YAMLLINT_ISSUES=$((YAMLLINT_ISSUES+1))
            WARNINGS=$((WARNINGS+1))
        fi
    done
    
    if [ $YAMLLINT_ISSUES -eq 0 ]; then
        echo -e "${GREEN}✓ All YAML files passed yamllint checks.${NC}"
    else
        echo -e "${YELLOW}Warning: ${YAMLLINT_ISSUES} files have yamllint issues.${NC}"
    fi
    
    # Clean up temporary config
    rm "$YAMLLINT_CONFIG"
else
    echo -e "\n${YELLOW}Step 3: Skipping yamllint checks.${NC}"
fi

# Step 4: Check for Azure DevOps pipeline best practices
echo -e "\n${YELLOW}Step 4: Checking Azure DevOps pipeline best practices...${NC}"
PIPELINE_FILES=$(find "${DIR_TO_VALIDATE}" -path "*/pipeline-templates/*.yml" -o -path "*/.github/workflows/*.yml")

if [ -n "$PIPELINE_FILES" ]; then
    PIPELINE_ISSUES=0
    
    for file in $PIPELINE_FILES; do
        # Check for timeout settings
        if ! grep -q "timeoutInMinutes:" "$file"; then
            echo -e "${YELLOW}Warning: $file might be missing timeout settings.${NC}"
            PIPELINE_ISSUES=$((PIPELINE_ISSUES+1))
        fi
        
        # Check for proper trigger configuration
        if ! grep -q "trigger:" "$file" && ! grep -q "pr:" "$file" && ! grep -q "schedules:" "$file"; then
            echo -e "${YELLOW}Warning: $file might be missing trigger configuration.${NC}"
            PIPELINE_ISSUES=$((PIPELINE_ISSUES+1))
        fi
        
        # Check for proper pool configuration
        if ! grep -q "pool:" "$file"; then
            echo -e "${YELLOW}Warning: $file might be missing pool configuration.${NC}"
            PIPELINE_ISSUES=$((PIPELINE_ISSUES+1))
        fi
    done
    
    if [ $PIPELINE_ISSUES -eq 0 ]; then
        echo -e "${GREEN}✓ All pipeline files follow best practices.${NC}"
    else
        echo -e "${YELLOW}Warning: ${PIPELINE_ISSUES} pipeline best practice issues found.${NC}"
        WARNINGS=$((WARNINGS+PIPELINE_ISSUES))
    fi
else
    echo -e "${YELLOW}No pipeline files found. Skipping pipeline best practices check.${NC}"
fi

# Step 5: Check for hardcoded secrets
echo -e "\n${YELLOW}Step 5: Checking for hardcoded secrets...${NC}"
if grep -r -E "(password|secret|token|key).*:.*[A-Za-z0-9/\+]{8,}" --include="*.yml" --include="*.yaml" "${DIR_TO_VALIDATE}"; then
    echo -e "${RED}Warning: Potential hardcoded secrets found. Please review the above files.${NC}"
    WARNINGS=$((WARNINGS+1))
else
    echo -e "${GREEN}✓ No hardcoded secrets found.${NC}"
fi

# Clean up temporary script
rm "$TMP_SCRIPT"

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