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
