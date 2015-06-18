# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition


. $ScriptPath"\2 K2 App Deployment\K2AppDeploymentFunctions.ps1"

# Load Config
[xml]$config = Get-Content $ScriptPath"\2 K2 App Deployment\K2AppDeploymentConfig.xml"

set-alias installutil $env:windir\Microsoft.NET\Framework64\v4.0.30319\installutil
installutil -u /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
installutil -i /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
Add-PSSnapin SourceCode.Deployment.PowerShell

# Get configuration values
$K2ConnectionString = $config.Packages.Configuration.K2ConnectionString
$K2Directory = $config.Packages.Configuration.K2Directory
$K2Server = $config.Packages.Configuration.K2Server



# PRE DEPLOY SETPS
    $ServiceTypesConfig = $config.Packages.Apps.PreDeploy.ServiceTypes

    foreach($ServiceTypeConfig in $ServiceTypesConfig.ServiceType)
    {
        $STCopyPath = $ServiceTypeConfig.BasePath + "\*"
        $K2ServiceBrokerDir = $K2Directory + "\ServiceBroker"
        Copy-Item $STCopyPath $K2ServiceBrokerDir

        $STPath = $ServiceTypeConfig.BasePath + "\" + $ServiceTypeConfig.Dll

        if ($ServiceTypeConfig.Guid -ne $null -or $ServiceTypeConfig.Guid -ne "") 
        {
            New-K2ServiceType -K2ConnectionString $K2ConnectionString -ServiceTypeSystemName $ServiceTypeConfig.Name -ServiceTypeDisplayName $ServiceTypeConfig.DisplayName -ServiceTypeDescription $ServiceTypeConfig.Description -ServiceTypeAssemblyPath $STPath -ServiceTypeClass $ServiceTypeConfig.Class -ServiceTypeGuid $ServiceTypeConfig.Guid
        } 
        else 
        {
            New-K2ServiceType -K2ConnectionString $K2ConnectionString -ServiceTypeSystemName $ServiceTypeConfig.Name -ServiceTypeDisplayName $ServiceTypeConfig.DisplayName -ServiceTypeDescription $ServiceTypeConfig.Description -ServiceTypeAssemblyPath $STPath -ServiceTypeClass $ServiceTypeConfig.Class
        }




    }

    # install other pre reqs





# DEPLOY NON-SHAREPOINT APPS
$AppsConfig = $config.Packages.Apps
foreach($AppConfig in $AppsConfig.App)
{



    # install K2 kspx apps    
    
    Write-Host -ForegroundColor Yellow "STARTING:" ($ScriptPath + $AppConfig.Package) "deployment"

    Deploy-Package ($ScriptPath + $AppConfig.Package) -ConnectionString $K2ConnectionString -NoAnalyze

    Write-Host -ForegroundColor Green "FINISHED:" ($ScriptPath + $AppConfig.Package) "deployment"
    

}



# POST DEPLOY STEPS
