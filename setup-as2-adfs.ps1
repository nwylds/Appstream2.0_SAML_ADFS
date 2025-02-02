# Install AD and ADFS
Install-WindowsFeature AD-Domain-Services, ADLDS, DNS, RSAT-AD-AdminCenter, RSAT-AD-PowerShell -IncludeManagementTools
Install-WindowsFeature ADFS-Federation -IncludeManagementTools

# Define domain
$DomainName = "appstream.local"
$SafeModePassword = ConvertTo-SecureString "YourSafeModeAdminPassword" -AsPlainText -Force

# Create AD Domain
Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $SafeModePassword -Force
