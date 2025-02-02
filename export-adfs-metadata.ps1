# Export ADFS Metadata
$FederationServiceName = "fs.appstream.local"
$SAMLMetadataPath = "C:\\Scripts\\ADFS-Metadata.xml"
$metadataUrl = "https://$FederationServiceName/FederationMetadata/2007-06/FederationMetadata.xml"
Invoke-WebRequest -Uri $metadataUrl -OutFile $SAMLMetadataPath

# Upload metadata to AWS IAM
aws iam create-saml-provider --name "ADFS-Provider" --saml-metadata-document file://$SAMLMetadataPath
