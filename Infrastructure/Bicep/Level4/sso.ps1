Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

Connect-MgGraph -Scopes "Application.Read.All","Application-RemoteDesktopConfig.ReadWrite.All"

$MSRDspId = (Get-MgServicePrincipal -Filter "AppId eq 'a4a365df-50f1-4397-bc59-1a1564b8bb9c'").Id
$WCLspId = (Get-MgServicePrincipal -Filter "AppId eq '270efc09-cd0d-444b-a71f-39af4910ec45'").Id


If ((Get-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $MSRDspId) -ne $true) {
    Update-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $MSRDspId -IsRemoteDesktopProtocolEnabled
}

If ((Get-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $WCLspId) -ne $true) {
    Update-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $WCLspId -IsRemoteDesktopProtocolEnabled
}

Get-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $MSRDspId
Get-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $WCLspId



$tdg = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphTargetDeviceGroup
$tdg.Id = "2e822894-7b05-4c0a-9698-1c04ea8ec1cc"
$tdg.DisplayName = "ACC_AVD_Users"

New-MgServicePrincipalRemoteDesktopSecurityConfigurationTargetDeviceGroup -ServicePrincipalId $MSRDspId -BodyParameter $tdg
New-MgServicePrincipalRemoteDesktopSecurityConfigurationTargetDeviceGroup -ServicePrincipalId $WCLspId -BodyParameter $tdg