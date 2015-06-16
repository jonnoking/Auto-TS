Set-ExecutionPolicy RemoteSigned

## Update Management Web.Config
# Get K2 install directory from the registry
$k2InstallDir = (get-itemproperty -path "hklm:\software\sourcecode\blackpearl\blackpearl core").InstallDir

# Load SmartForms Web.Config
[xml]$xmlSmartFormsWebConfig = Get-Content ($k2InstallDir + "K2 smartforms Runtime\Web.Config")

# Get values from SmartForms Web.Config
$hostname = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/appSettings/add[@key='HostName']").value
$hostPort= $xmlSmartFormsWebConfig.SelectSingleNode("configuration/appSettings/add[@key='HostPort']").value
$workflowPort = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/appSettings/add[@key='WorkflowPort']").value
$authKey = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/appSettings/add[@key='Authentication.Key']").value
$authIV = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/appSettings/add[@key='Authentication.IV']").value

$machineKeyDecryptionKey = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/system.web/machineKey").decryptionKey
$machineKeyValidationKey = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/system.web/machineKey").validationKey
[string]$runtimeRealmUrl = $xmlSmartFormsWebConfig.SelectSingleNode("configuration/system.identityModel.services/federationConfiguration/wsFederation").realm

# Get Management/Web.Config
[xml]$xmlManagement = Get-Content ($k2InstallDir + "Management\Web.Config")

# Change values to match SmartForms Web.Config
$xmlManagement.SelectSingleNode("configuration/appSettings/add[@key='HostName']").value = $hostname
$xmlManagement.SelectSingleNode("configuration/appSettings/add[@key='HostPort']").value = $hostPort
$xmlManagement.SelectSingleNode("configuration/appSettings/add[@key='WorkflowPort']").value = $workflowPort
$xmlManagement.SelectSingleNode("configuration/appSettings/add[@key='Authentication.Key']").value = $authKey
$xmlManagement.SelectSingleNode("configuration/appSettings/add[@key='Authentication.IV']").value = $authIV
$xmlManagement.SelectSingleNode("configuration/appSettings/add[@key='RuntimeUrl']").value = $runtimeRealmUrl.TrimEnd('/') + "/Runtime/"

$xmlManagement.SelectSingleNode("configuration/system.web/machineKey").decryptionKey = $machineKeyDecryptionKey
$xmlManagement.SelectSingleNode("configuration/system.web/machineKey").validationKey = $machineKeyValidationKey
$xmlManagement.SelectSingleNode("configuration/system.identityModel.services/federationConfiguration/wsFederation").realm = $runtimeRealmUrl.Replace("Runtime","Management")

#Save Management Web.Config File
$xmlManagement.Save($k2InstallDir + "Management\Web.Config")

##  Refresh ServiceInstance
#  Load SourceCode.SmartObjects.Services.Management assembly
Add-Type -Path ($k2InstallDir + "Bin\SourceCode.HostClientAPI.dll")
Add-Type -Path ($k2InstallDir + "Bin\SourceCode.SmartObjects.Services.Management.dll")

#  Create connection string
$connBuilder = New-Object SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder
$connBuilder.Host = $hostname
$connBuilder.Port = "5555"
$connBuilder.Integrated = "true"
$connBuilder.IsPrimaryLogin = "true"

$managementServiceInstanceGuid = New-Object Guid("5d273ad6-e27a-46f8-be67-198b36085f99")

#  Create ServiceManagementServer API
$managementServer = New-Object SourceCode.SmartObjects.Services.Management.ServiceManagementServer
$managementServer.CreateConnection()

Try
{
    $managementServer.Connection.Open($connBuilder.ConnectionString)
    
    # RefreshServiceInstance
    $managementServer.RefreshServiceInstance($managementServiceInstanceGuid)
}
Finally
{
  $managementServer.Connection.Dispose()
}

#  Deploy P&D package - K2Management.kspx
set-alias installutil $env:windir\Microsoft.NET\Framework64\v4.0.30319\installutil
installutil -u /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
installutil -i /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
Add-PSSnapin SourceCode.Deployment.PowerShell

Deploy-Package 'K2Management.kspx' -ConnectionString 'Integrated=True;IsPrimaryLogin=True;Authenticate=True;EncryptedPassword=False;Host=localhost;Port=5555' -NoAnalyze

Deploy-Package -
