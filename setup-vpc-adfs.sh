#!/bin/bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=AD-VPC}]'
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.2.0/24 --availability-zone us-east-1b

aws ec2 create-security-group --group-name AD-Security-Group --description "Security group for Active Directory" --vpc-id <VPC_ID>
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 53 --cidr 10.0.0.0/16
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 389 --cidr 10.0.0.0/16
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 636 --cidr 10.0.0.0/16
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 443 --cidr 0.0.0.0/0 # Required for user authentication

aws ec2 create-dhcp-options --dhcp-configuration "Key=domain-name,Values=appstream.local" "Key=domain-name-servers,Values=10.0.1.10"
aws ec2 associate-dhcp-options --dhcp-options-id <DHCP_OPTIONS_ID> --vpc-id <VPC_ID>
