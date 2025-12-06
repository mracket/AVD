$Timestamp = Get-Date -Format "yyyy-MM-dd"
$Modules = Get-ChildItem -Path . -Filter *.bicep -Recurse
$Registry = "acrcloudninjalevel6"

foreach ($Module in $Modules) {
    $FilePath = $Module.FullName
    $ModuleName = $Module.BaseName
    
    # Publish with timestamped tag
    Write-Host "Publishing $ModuleName with tag $Timestamp..."
    az bicep publish --file $FilePath --target "br:${Registry}.azurecr.io/${ModuleName}:${Timestamp}" 

}

