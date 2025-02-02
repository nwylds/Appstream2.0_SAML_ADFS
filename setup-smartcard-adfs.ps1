Set-AdfsGlobalAuthenticationPolicy -PrimaryAuthenticationProvider "CertificateAuthentication"
Set-ADDefaultDomainPasswordPolicy -SmartCardRequired $true
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\\PathToYourCert.cer")
Set-AdUser -Identity "username" -SmartcardLogonRequired $true -Certificates @{add=$cert.RawData}
Set-AdfsRelyingPartyTrust -TargetName "AppStream2" -PrimaryAuthenticationProvider "CertificateAuthentication"
