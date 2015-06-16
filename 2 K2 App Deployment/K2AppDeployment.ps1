# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load Config
[xml]$config = Get-Content "C:\Development\Auto-TS\2 K2 App Deployment\K2AppDeploymentConfig.xml"

set-alias installutil $env:windir\Microsoft.NET\Framework64\v4.0.30319\installutil
installutil -u /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
installutil -i /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
Add-PSSnapin SourceCode.Deployment.PowerShell

# Get configuration values
$K2ConnectionString = $config.Packages.Configuration.K2ConnectionString




# PRE DEPLOY SETPS
    $ServiceTypesConfig = $AppConfig.PreDeploy.ServiceTypes

    foreach($ServiceTypeConfig in $ServiceTypesConfig)
    {
        # install service types
        # THE CODE BELOW IS INCORRECT IGNORE

        break;


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

    }

    # install other pre reqs





# DEPLOY NON-SHAREPOINT APPS
$AppsConfig = $config.Packages.Apps
foreach($AppConfig in $AppsConfig.App)
{



    # install K2 kspx apps    
    
    Write-Host -ForegroundColor Yellow "STARTING:" $AppConfig.Package "deployment"

    Deploy-Package $AppConfig.Package -ConnectionString $K2ConnectionString -NoAnalyze

    Write-Host -ForegroundColor Green "COMPLETED:" $AppConfig.Package "deployment"
    

}



# POST DEPLOY STEPS
