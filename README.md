# Deploying Active Directory, ADFS, and Amazon AppStream 2.0 on AWS: A Complete Guide

## Introduction

In this blog, we will walk through the step-by-step process of setting up **Active Directory (AD) and Active Directory Federation Services (ADFS)** on an AWS EC2 instance. Additionally, we will integrate **Amazon AppStream 2.0** with **SAML authentication** using AWS IAM Identity Center.

By the end of this guide, you'll have a fully functional **Active Directory domain**, **federated authentication via ADFS**, and **AppStream 2.0 configured for single sign-on (SSO)**. 🚀

---

## Step 1: Launch a Windows Server 2022 EC2 Instance

### Automating Deployment with a Bash Script

The following script automates the provisioning of a Windows Server 2022 EC2 instance. It sets up security groups, assigns an SSH key, and installs required configurations.

#### **Bash Script (`setup-ec2-adfs.sh`)**

```bash
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
```
## Step 2: Configure VPC and DNS for Domain Connectivity

### Setting Up VPC for AD and ADFS

To ensure all instances in the VPC can communicate with the Active Directory domain, we need to configure subnets, security groups, and routing.

#### **Steps to Configure VPC:**

1. **Create a VPC**
   ```bash
   aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=AD-VPC}]'
   ```
2. **Create Subnets for AD and ADFS**
   ```bash
   aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
   aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
   ```
3. **Set Up Security Groups for AD Communication**
   ```bash
   aws ec2 create-security-group --group-name AD-Security-Group --description "Security group for Active Directory" --vpc-id <VPC_ID>
   aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 53 --cidr 10.0.0.0/16
   aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 389 --cidr 10.0.0.0/16
   aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 636 --cidr 10.0.0.0/16
   aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 443 --cidr 0.0.0.0/0 # Required for user authentication
   ```

### Configuring DNS for Domain Connectivity

To allow all instances in the VPC to resolve the domain, configure the DHCP options set.

```bash
aws ec2 create-dhcp-options --dhcp-configuration "Key=domain-name,Values=appstream.local" "Key=domain-name-servers,Values=10.0.1.10"
```

Attach the DHCP options set to the VPC:

```bash
aws ec2 associate-dhcp-options --dhcp-options-id <DHCP_OPTIONS_ID> --vpc-id <VPC_ID>
```
---

## Step 3: Configure Active Directory & ADFS

### Setting Up Active Directory Domain Services

The script below installs **Active Directory Domain Services (AD DS)** and creates a new domain.

#### **PowerShell Script (`setup-ad-appstream.ps1`)**

```powershell
# Install AD and ADFS
Install-WindowsFeature AD-Domain-Services, ADLDS, DNS, RSAT-AD-AdminCenter, RSAT-AD-PowerShell -IncludeManagementTools
Install-WindowsFeature ADFS-Federation -IncludeManagementTools

# Define domain
$DomainName = "appstream.local"
$SafeModePassword = ConvertTo-SecureString "YourSafeModeAdminPassword" -AsPlainText -Force

# Create AD Domain
Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $SafeModePassword -Force
```

🔹 **Why This Matters?** This script automates the process of setting up a fully functional **Windows Active Directory Domain** and **ADFS for authentication**.

---

## Step 4: Configure ADFS for AWS IAM Integration

Once the ADFS role is installed, we must export its **SAML metadata** and configure it in **AWS IAM Identity Provider**.

#### **PowerShell Script (`export-adfs-metadata.ps1`)**

```powershell
# Export ADFS Metadata
$FederationServiceName = "fs.appstream.local"
$SAMLMetadataPath = "C:\\Scripts\\ADFS-Metadata.xml"
$metadataUrl = "https://$FederationServiceName/FederationMetadata/2007-06/FederationMetadata.xml"
Invoke-WebRequest -Uri $metadataUrl -OutFile $SAMLMetadataPath

# Upload metadata to AWS IAM
aws iam create-saml-provider --name "ADFS-Provider" --saml-metadata-document file://$SAMLMetadataPath
```

🔹 **Why This Matters?** This enables **federated authentication**, allowing users to log in via their existing AD credentials.

---

## Step 5: Creating an IAM Role for AppStream Users

To allow **federated access** to AppStream, an **IAM role** must be created.

#### **Bash Script (`create-appstream-iam-role.sh`)**

```bash
#!/bin/bash
AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"
SAML_PROVIDER_ARN=$(aws iam list-saml-providers --query "SAMLProviderList[0].Arn" --output text)

# Create IAM Policy
cat <<EOF > appstream-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["appstream:Stream"],
            "Resource": "*"
        }
    ]
}
EOF

# Create IAM Role
aws iam create-role --role-name AppStreamSAMLRole --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"Federated": "'$SAML_PROVIDER_ARN'"},
            "Action": "sts:AssumeRoleWithSAML",
            "Condition": {"StringEquals": {"SAML:aud": "https://signin.aws.amazon.com/saml"}}
        }
    ]
}'
```

🔹 **Why This Matters?** This IAM role ensures that **only federated users** can access AppStream 2.0.

---

## Step 6: Setting Up Smart Card Authentication with ADFS and AppStream 2.0

To enable **smart card authentication**, follow these steps:

### **1. Enable Smart Card Authentication in ADFS**

```powershell
Set-AdfsGlobalAuthenticationPolicy -PrimaryAuthenticationProvider "CertificateAuthentication"
```

### **2. Configure Smart Card Group Policy in Active Directory**

```powershell
Set-ADDefaultDomainPasswordPolicy -SmartCardRequired $true
```

### **3. Map Smart Card Certificates to AD Users**

```powershell
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\\PathToYourCert.cer")
Set-AdUser -Identity "username" -SmartcardLogonRequired $true -Certificates @{add=$cert.RawData}
```

### **4. Configure ADFS for Smart Card Authentication with SAML**

```powershell
Set-AdfsRelyingPartyTrust -TargetName "AppStream2" -PrimaryAuthenticationProvider "CertificateAuthentication"
```

🔹 **Why This Matters?** Smart card authentication adds an **extra layer of security** by requiring a physical token for authentication.

---

## Conclusion

Congratulations! 🎉 You've successfully set up **Active Directory & ADFS**, **AWS IAM SAML Authentication**, and **Smart Card Authentication** for **AppStream 2.0**. 🚀
