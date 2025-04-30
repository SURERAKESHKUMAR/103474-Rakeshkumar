package helpers

import (
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
)

// RandomAwsRegion returns a random AWS region to use for testing
func RandomAwsRegion(t *testing.T) string {
	// These are stable AWS regions that support ECS
	availableRegions := []string{
		"us-east-1",
		"us-east-2",
		"us-west-1",
		"us-west-2",
		"eu-west-1",
		"eu-central-1",
	}

	return random.RandomString(availableRegions)
}

// GetDefaultAwsRegion returns the default AWS region for testing
func GetDefaultAwsRegion() string {
	return "us-west-2"
}

// GetAwsSession creates an AWS session for the given region
func GetAwsSession(region string) (*session.Session, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		return nil, err
	}
	return sess, nil
}

// VerifyVpcExists checks if a VPC with the given ID exists
func VerifyVpcExists(t *testing.T, region string, vpcId string) {
	sess, err := GetAwsSession(region)
	require.NoError(t, err)

	ec2Client := ec2.New(sess)
	input := &ec2.DescribeVpcsInput{
		VpcIds: []*string{aws.String(vpcId)},
	}

	result, err := ec2Client.DescribeVpcs(input)
	require.NoError(t, err)
	require.Equal(t, 1, len(result.Vpcs), fmt.Sprintf("Expected to find 1 VPC with ID %s, but found %d", vpcId, len(result.Vpcs)))
}

// VerifySubnetsExist checks if subnets with the given IDs exist
func VerifySubnetsExist(t *testing.T, region string, subnetIds []string) {
	sess, err := GetAwsSession(region)
	require.NoError(t, err)

	ec2Client := ec2.New(sess)
	
	var awsSubnetIds []*string
	for _, id := range subnetIds {
		awsSubnetIds = append(awsSubnetIds, aws.String(id))
	}
	
	input := &ec2.DescribeSubnetsInput{
		SubnetIds: awsSubnetIds,
	}

	result, err := ec2Client.DescribeSubnets(input)
	require.NoError(t, err)
	require.Equal(t, len(subnetIds), len(result.Subnets), fmt.Sprintf("Expected to find %d subnets, but found %d", len(subnetIds), len(result.Subnets)))
}

// VerifyEcsClusterExists checks if an ECS cluster with the given name exists
func VerifyEcsClusterExists(t *testing.T, region string, clusterName string) {
	sess, err := GetAwsSession(region)
	require.NoError(t, err)

	ecsClient := ecs.New(sess)
	input := &ecs.DescribeClustersInput{
		Clusters: []*string{aws.String(clusterName)},
	}

	result, err := ecsClient.DescribeClusters(input)
	require.NoError(t, err)
	require.Equal(t, 1, len(result.Clusters), fmt.Sprintf("Expected to find 1 ECS cluster with name %s, but found %d", clusterName, len(result.Clusters)))
	require.Equal(t, "ACTIVE", *result.Clusters[0].Status, fmt.Sprintf("Expected ECS cluster %s to be ACTIVE, but it was %s", clusterName, *result.Clusters[0].Status))
}

// VerifySecurityGroupExists checks if a security group with the given ID exists
func VerifySecurityGroupExists(t *testing.T, region string, securityGroupId string) {
	sess, err := GetAwsSession(region)
	require.NoError(t, err)

	ec2Client := ec2.New(sess)
	input := &ec2.DescribeSecurityGroupsInput{
		GroupIds: []*string{aws.String(securityGroupId)},
	}

	result, err := ec2Client.DescribeSecurityGroups(input)
	require.NoError(t, err)
	require.Equal(t, 1, len(result.SecurityGroups), fmt.Sprintf("Expected to find 1 security group with ID %s, but found %d", securityGroupId, len(result.SecurityGroups)))
}