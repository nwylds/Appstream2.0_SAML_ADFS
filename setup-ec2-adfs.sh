#!/bin/bash

# AWS Configuration
AWS_REGION="us-east-1"
INSTANCE_TYPE="m5.large"
AMI_ID="ami-0c02fb55956c7d316" # Windows Server 2022 AMI
KEY_NAME="my-aws-key"
SECURITY_GROUP="sg-0123456789abcdef"
SUBNET_ID="subnet-0123456789abcdef"
TAG="ADFS-Server"

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG}]" \
    --query "Instances[0].InstanceId" --output text)

echo "Launching EC2 instance: $INSTANCE_ID"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance $INSTANCE_ID is now running."
