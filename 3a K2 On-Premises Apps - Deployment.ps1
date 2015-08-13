# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition


. $ScriptPath"\3z K2 On-Premises Apps - Functions.ps1"

# Load Config
[xml]$config = Get-Content $ScriptPath"\3 K2 On-Premises Apps - Config.xml"
#[xml]$config = Get-Content $ScriptPath"\99 K2 On-Premises Try Now - Config.xml"

set-alias installutil $env:windir\Microsoft.NET\Framework64\v4.0.30319\installutil
installutil -u /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
installutil -i /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL'
Add-PSSnapin SourceCode.Deployment.PowerShell

# Get configuration values
$K2ConnectionString = $config.Environment.Configuration.K2HostServerConnectionString
$K2WorkflowConnectionString = $config.Environment.Configuration.K2WorkflowConnectionString
$K2Directory = $config.Environment.Configuration.K2Directory
$K2Server = $config.Environment.Configuration.K2Server
$k2InstallDir = $config.Environment.Configuration.K2Directory



#New-K2WorkflowUserPermission -K2WorkflowConnectionString $K2ConnectionString -Workflow "Workflow\Leave Request Approval" -UserFQN "K2:DENALLIX\CODI" -Admin $false -Start $true -View $false -ViewParticipate $false -ServerEvent $false
#New-K2WorkflowUserPermission -K2WorkflowConnectionString $K2ConnectionString -Workflow "Workflow\Leave Request Approval" -UserFQN "K2:DENALLIX\JONNO" -Admin $true -Start $true -View $false -ViewParticipate $false -ServerEvent $false
#New-K2WorkflowGroupPermission -K2WorkflowConnectionString $K2ConnectionString -Workflow "Workflow\Leave Request Approval" -GroupFQN "K2:DENALLIX\Domain Users" -Admin $true -Start $false -View $false -ViewParticipate $false -ServerEvent $false

#New-K2RoleMember -K2ConnectionString $K2ConnectionString -Role "HR" -RoleMember "K2:denallix\CODI" -RoleMemberType "user"
#New-K2RoleMember -K2ConnectionString $K2ConnectionString -Role "HR" -RoleMember "K2:denallix\Domain Users" -RoleMemberType "group"

#Get-K2RoleMember -K2ConnectionString $K2ConnectionString -Role "HR" -RoleMember "K2:denallix\Domain Users"

#Delete-K2RoleMember -K2ConnectionString $K2ConnectionString -Role "HR" -RoleMember "K2:denallix\Domain Users"

#return


# PRE DEPLOY SETPS

# INSTALL SERVICE TYPES
    $ServiceTypesConfig = $config.Environment.PreDeploy.ServiceTypes

    foreach($ServiceTypeConfig in $ServiceTypesConfig.ServiceType)
    {
        $STCopyPath = $ScriptPath+$ServiceTypeConfig.BasePath + "\*"
        $K2ServiceBrokerDir = $K2Directory + "\ServiceBroker"
        Copy-Item $STCopyPath $K2ServiceBrokerDir

        $STPath = $ScriptPath+$ServiceTypeConfig.BasePath + "\" + $ServiceTypeConfig.Dll

        if ($ServiceTypeConfig.Guid -ne $null -or $ServiceTypeConfig.Guid -ne "") 
        {
            New-K2ServiceType -K2ConnectionString $K2ConnectionString -ServiceTypeSystemName $ServiceTypeConfig.SystemName -ServiceTypeDisplayName $ServiceTypeConfig.DisplayName -ServiceTypeDescription $ServiceTypeConfig.Description -ServiceTypeAssemblyPath $STPath -ServiceTypeClass $ServiceTypeConfig.Class -ServiceTypeGuid $ServiceTypeConfig.Guid
        } 
        else 
        {
            New-K2ServiceType -K2ConnectionString $K2ConnectionString -ServiceTypeSystemName $ServiceTypeConfig.SystemName -ServiceTypeDisplayName $ServiceTypeConfig.DisplayName -ServiceTypeDescription $ServiceTypeConfig.Description -ServiceTypeAssemblyPath $STPath -ServiceTypeClass $ServiceTypeConfig.Class
        }        
    }

# INSTALL CUSTOM CONTROLS
    $ControlsConfig = $config.Environment.PreDeploy.CustomControls

    foreach($ControlConfig in $ControlsConfig.Control)
    {
        $ControlName = $ControlConfig.GetAttribute("Name")

        Write-Host -ForegroundColor Yellow "STARTING: Install of custom control " $ControlName

        # need to validate if $ControlConfig.InstallBatchFile is a valid path

        $InstallBatchFile = $ScriptPath+$ControlConfig.InstallBatchFile
        
        $A = Start-Process -FilePath $InstallBatchFile -Wait -passthru;$a.ExitCode

        Write-Host -ForegroundColor Yellow "FINISHED: Install of custom control " $ControlName

    }


# COPY FILES - PRE DEPLOY

    $CopiesConfig = $config.Environment.PreDeploy.CopyFiles

    foreach($CopyConfig in $CopiesConfig.Copy)
    {
        Set-K2CopyDeploy -CopyConfig $CopyConfig
    }


# EXECUTE OTHER POWERSHELL CMDLETS - PRE DEPLOY
    $PowerShellConfig = $config.Environment.PreDeploy.PowerShell

    foreach($CmdletConfig in $PowerShellConfig.Cmdlet)
    {
        Set-K2ExecuteScriptDeploy -CmdletConfig $CmdletConfig
    }


# DEPLOY SHAREPOINT APPS

#### TO DO


# DEPLOY NON-SHAREPOINT APPS
$AppsConfig = $config.Environment.Apps
foreach($AppConfig in $AppsConfig.App)
{

    # install K2 kspx apps    
    
    Write-Host -ForegroundColor Yellow "STARTING:" ($ScriptPath + $AppConfig.Package) "deployment"

    Deploy-Package ($ScriptPath + $AppConfig.Package) -ConnectionString $K2ConnectionString -NoAnalyze

    Write-Host -ForegroundColor Green "FINISHED:" ($ScriptPath + $AppConfig.Package) "deployment"
    
}



# POST DEPLOY STEPS


# CONFIGURE WORKFLOWS
$WorkflowConfig = $config.Environment.PostDeploy.WorkflowConfig
foreach($Workflow in $WorkflowConfig.Workflow)
{    
    foreach($WorkflowPermission in $Workflow.ProcessRights) 
    {
        if($WorkflowPermission.Type.ToLower() -eq "group")
        {
            New-K2WorkflowGroupPermission -K2WorkflowConnectionString $K2ConnectionString -Workflow $Workflow.Name -GroupFQN $WorkflowPermission.FQN -Admin $WorkflowPermission.Admin -Start $WorkflowPermission.Start -View $WorkflowPermission.View -ViewParticipate $WorkflowPermission.ViewParticipate -ServerEvent $WorkflowPermission.ServerEvent
        }
        else
        {
            New-K2WorkflowUserPermission -K2WorkflowConnectionString $K2ConnectionString -Workflow $Workflow.Name -UserFQN $WorkflowPermission.FQN -Admin $WorkflowPermission.Admin -Start $WorkflowPermission.Start -View $WorkflowPermission.View -ViewParticipate $WorkflowPermission.ViewParticipate -ServerEvent $WorkflowPermission.ServerEvent
        }
    }
}

# CONFIGURE ROLES
$RolesConfig = $config.Environment.PostDeploy.Roles
foreach($Role in $RolesConfig.Role)
{
    # Create Role if it doesn't exist - if role already exists nothing will happen
    New-K2Role -Name $Role.Name

    foreach($Include in $Role.Include)
    {
        New-K2RoleMember -K2ConnectionString $K2ConnectionString -Role $Role.Name -RoleMember $Include.FQN -RoleMemberType $Include.Type -IncludeExclude "include"
    }

    foreach($Exclude in $Role.Exclude)
    {
        New-K2RoleMember -K2ConnectionString $K2ConnectionString -Role $Role.Name -RoleMember $Exclude.FQN -RoleMemberType $Exclude.Type -IncludeExclude "exclude"
    }
}


# COPY FILES - POST DEPLOY

    $CopiesConfig = $config.Environment.PostDeploy.CopyFiles

    foreach($CopyConfig in $CopiesConfig.Copy)
    {
        Set-K2CopyDeploy -CopyConfig $CopyConfig
    }


# EXECUTE OTHER POWERSHELL CMDLETS - POST DEPLOY
    $PowerShellConfig = $config.Environment.PostDeploy.PowerShell

    foreach($CmdletConfig in $PowerShellConfig.Cmdlet)
    {
        Set-K2ExecuteScriptDeploy -CmdletConfig $CmdletConfig
    }

