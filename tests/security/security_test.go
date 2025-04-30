package test

import (
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ecs-infrastructure/tests/helpers"
)

func TestSecurityModuleBasic(t *testing.T) {
	t.Parallel()

	// Generate a random name prefix to prevent collisions
	uniqueID := random.UniqueId()
	namePrefix := fmt.Sprintf("terratest-%s", uniqueID)

	// Pick a random AWS region to test in
	awsRegion := helpers.GetDefaultAwsRegion()

	// Construct the terraform options with default retryable errors
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "./fixtures/basic",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region":  awsRegion,
			"name_prefix": namePrefix,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	albSecurityGroupID := terraform.Output(t, terraformOptions, "alb_security_group_id")
	ecsSecurityGroupID := terraform.Output(t, terraformOptions, "ecs_security_group_id")
	ecsTaskExecutionRoleARN := terraform.Output(t, terraformOptions, "ecs_task_execution_role_arn")
	ecsTaskRoleARN := terraform.Output(t, terraformOptions, "ecs_task_role_arn")

	// Verify that the security groups exist
	helpers.VerifySecurityGroupExists(t, awsRegion, albSecurityGroupID)
	helpers.VerifySecurityGroupExists(t, awsRegion, ecsSecurityGroupID)

	// Verify that the IAM roles exist
	verifyIamRoleExists(t, awsRegion, ecsTaskExecutionRoleARN)
	verifyIamRoleExists(t, awsRegion, ecsTaskRoleARN)

	// Verify security group rules
	verifyAlbSecurityGroupRules(t, awsRegion, albSecurityGroupID)
	verifyEcsSecurityGroupRules(t, awsRegion, ecsSecurityGroupID, albSecurityGroupID)
}

func TestSecurityModuleCustomPort(t *testing.T) {
	t.Parallel()

	// Generate a random name prefix to prevent collisions
	uniqueID := random.UniqueId()
	namePrefix := fmt.Sprintf("terratest-%s", uniqueID)

	// Pick a random AWS region to test in
	awsRegion := helpers.GetDefaultAwsRegion()

	// Custom container port
	containerPort := 8080

	// Construct the terraform options with default retryable errors
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "./fixtures/basic",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region":     awsRegion,
			"name_prefix":    namePrefix,
			"container_port": containerPort,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	albSecurityGroupID := terraform.Output(t, terraformOptions, "alb_security_group_id")
	ecsSecurityGroupID := terraform.Output(t, terraformOptions, "ecs_security_group_id")

	// Verify security group rules for custom port
	verifyAlbSecurityGroupRules(t, awsRegion, albSecurityGroupID)
	verifyEcsSecurityGroupRulesCustomPort(t, awsRegion, ecsSecurityGroupID, albSecurityGroupID, containerPort)
}

// Helper function to verify that an IAM role exists
func verifyIamRoleExists(t *testing.T, region string, roleARN string) {
	// Extract the role name from the ARN
	roleName := roleARN[roleARN.LastIndex("/")+1:]

	sess, err := helpers.GetAwsSession(region)
	require.NoError(t, err)

	iamClient := iam.New(sess)
	input := &iam.GetRoleInput{
		RoleName: aws.String(roleName),
	}

	_, err = iamClient.GetRole(input)
	require.NoError(t, err, fmt.Sprintf("Expected IAM role %s to exist", roleName))
}

// Helper function to verify ALB security group rules
func verifyAlbSecurityGroupRules(t *testing.T, region string, securityGroupID string) {
	sess, err := helpers.GetAwsSession(region)
	require.NoError(t, err)

	ec2Client := ec2.New(sess)
	input := &ec2.DescribeSecurityGroupsInput{
		GroupIds: []*string{aws.String(securityGroupID)},
	}

	result, err := ec2Client.DescribeSecurityGroups(input)
	require.NoError(t, err)
	require.Equal(t, 1, len(result.SecurityGroups))

	// Verify inbound rules (should allow HTTP and HTTPS from anywhere)
	inboundRules := result.SecurityGroups[0].IpPermissions
	assert.GreaterOrEqual(t, len(inboundRules), 2, "ALB security group should have at least 2 inbound rules (HTTP and HTTPS)")

	// Check for HTTP rule (port 80)
	httpRuleFound := false
	for _, rule := range inboundRules {
		if *rule.FromPort == 80 && *rule.ToPort == 80 && *rule.IpProtocol == "tcp" {
			httpRuleFound = true
			break
		}
	}
	assert.True(t, httpRuleFound, "ALB security group should allow inbound HTTP traffic (port 80)")

	// Check for HTTPS rule (port 443)
	httpsRuleFound := false
	for _, rule := range inboundRules {
		if *rule.FromPort == 443 && *rule.ToPort == 443 && *rule.IpProtocol == "tcp" {
			httpsRuleFound = true
			break
		}
	}
	assert.True(t, httpsRuleFound, "ALB security group should allow inbound HTTPS traffic (port 443)")
}

// Helper function to verify ECS security group rules
func verifyEcsSecurityGroupRules(t *testing.T, region string, ecsSecurityGroupID string, albSecurityGroupID string) {
	sess, err := helpers.GetAwsSession(region)
	require.NoError(t, err)

	ec2Client := ec2.New(sess)
	input := &ec2.DescribeSecurityGroupsInput{
		GroupIds: []*string{aws.String(ecsSecurityGroupID)},
	}

	result, err := ec2Client.DescribeSecurityGroups(input)
	require.NoError(t, err)
	require.Equal(t, 1, len(result.SecurityGroups))

	// Verify inbound rules (should allow traffic from ALB security group on container port)
	inboundRules := result.SecurityGroups[0].IpPermissions
	assert.GreaterOrEqual(t, len(inboundRules), 1, "ECS security group should have at least 1 inbound rule")

	// Check for rule allowing traffic from ALB security group
	albRuleFound := false
	for _, rule := range inboundRules {
		for _, group := range rule.UserIdGroupPairs {
			if *group.GroupId == albSecurityGroupID {
				albRuleFound = true
				break
			}
		}
	}
	assert.True(t, albRuleFound, "ECS security group should allow inbound traffic from ALB security group")
}

// Helper function to verify ECS security group rules with custom port
func verifyEcsSecurityGroupRulesCustomPort(t *testing.T, region string, ecsSecurityGroupID string, albSecurityGroupID string, containerPort int) {
	sess, err := helpers.GetAwsSession(region)
	require.NoError(t, err)

	ec2Client := ec2.New(sess)
	input := &ec2.DescribeSecurityGroupsInput{
		GroupIds: []*string{aws.String(ecsSecurityGroupID)},
	}

	result, err := ec2Client.DescribeSecurityGroups(input)
	require.NoError(t, err)
	require.Equal(t, 1, len(result.SecurityGroups))

	// Verify inbound rules (should allow traffic from ALB security group on custom container port)
	inboundRules := result.SecurityGroups[0].IpPermissions
	assert.GreaterOrEqual(t, len(inboundRules), 1, "ECS security group should have at least 1 inbound rule")

	// Check for rule allowing traffic from ALB security group on custom port
	customPortRuleFound := false
	for _, rule := range inboundRules {
		if *rule.FromPort == int64(containerPort) && *rule.ToPort == int64(containerPort) {
			for _, group := range rule.UserIdGroupPairs {
				if *group.GroupId == albSecurityGroupID {
					customPortRuleFound = true
					break
				}
			}
		}
	}
	assert.True(t, customPortRuleFound, fmt.Sprintf("ECS security group should allow inbound traffic from ALB security group on port %d", containerPort))
}