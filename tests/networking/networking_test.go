package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ecs-infrastructure/tests/helpers"
)

func TestNetworkingModuleBasic(t *testing.T) {
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
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpcCIDR := terraform.Output(t, terraformOptions, "vpc_cidr")
	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	natGatewayIDs := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	internetGatewayID := terraform.Output(t, terraformOptions, "internet_gateway_id")

	// Verify that the VPC exists
	helpers.VerifyVpcExists(t, awsRegion, vpcID)

	// Verify that the VPC CIDR is correct
	assert.Equal(t, "10.0.0.0/16", vpcCIDR)

	// Verify that the subnets exist
	helpers.VerifySubnetsExist(t, awsRegion, publicSubnetIDs)
	helpers.VerifySubnetsExist(t, awsRegion, privateSubnetIDs)

	// Verify the number of subnets
	assert.Equal(t, 2, len(publicSubnetIDs))
	assert.Equal(t, 2, len(privateSubnetIDs))

	// Verify that the NAT gateways exist
	for _, natGatewayID := range natGatewayIDs {
		aws.GetNatGatewayInfo(t, natGatewayID, awsRegion)
	}

	// Verify the number of NAT gateways
	assert.Equal(t, 2, len(natGatewayIDs))

	// Verify that the Internet Gateway exists
	aws.GetInternetGatewayInfo(t, internetGatewayID, awsRegion)
}

func TestNetworkingModuleCustomCIDR(t *testing.T) {
	t.Parallel()

	// Generate a random name prefix to prevent collisions
	uniqueID := random.UniqueId()
	namePrefix := fmt.Sprintf("terratest-%s", uniqueID)

	// Pick a random AWS region to test in
	awsRegion := helpers.GetDefaultAwsRegion()

	// Custom CIDR blocks
	vpcCIDR := "192.168.0.0/16"
	publicSubnetCIDRs := []string{"192.168.1.0/24", "192.168.2.0/24"}
	privateSubnetCIDRs := []string{"192.168.11.0/24", "192.168.12.0/24"}

	// Construct the terraform options with default retryable errors
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "./fixtures/basic",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region":           awsRegion,
			"name_prefix":          namePrefix,
			"vpc_cidr":             vpcCIDR,
			"public_subnet_cidrs":  publicSubnetCIDRs,
			"private_subnet_cidrs": privateSubnetCIDRs,
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
	actualVpcCIDR := terraform.Output(t, terraformOptions, "vpc_cidr")

	// Verify that the VPC CIDR is correct
	assert.Equal(t, vpcCIDR, actualVpcCIDR)
}