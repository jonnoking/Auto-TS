# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition


. $ScriptPath"\3z K2 On-Premises Apps - Functions.ps1"
. $ScriptPath"\1z SharePoint On-Premises - Functions.ps1"

# Load Config
#[xml]$config = Get-Content $ScriptPath"\3 K2 On-Premises Apps - Config.xml"
[xml]$config = Get-Content $ScriptPath"\99 K2 On-Premises Try Now - Config.xml"

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

$SiteUrl = "https://portal.denallix.com/denallix-bellevue"
$SiteName = "Denallix-Bellevue"
$ListName = "Leave Approval"
$ListId = "15afa672-15e1-4fc0-b410-84d7ef54285e"
$PackagePath = "C:\K2\SharePoint Apps\K2 Application Accelerator - Leave Request v1.1.kspx"
$SourceUrl = "https://portal.denallix.com/denallix-bellevue/Lists/Leave%20Approval/calendar.aspx"



# WORKS
#Set-K2SmOSPGenerateK2ArtifactsOnList -SiteUrl $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SourceUrl $SourceUrl -GenerateSmartForms $true -SetFormsUrl $true -GenerateReports $true
#return
#SET-K2SPRemoveK2ArtifactsFromList -ListId "eecc5ac4-99a6-4e05-94a2-e7781b3df8de"


#$SessionName = Set-K2SmOSPLoadPackage -SiteUrl $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -PackagePath $PackagePath

#$SessionName = Set-K2SmOSPRefactorSharepointArtifacts -SiteUrl $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SessionName $SessionName
#$SessionName = Set-K2SmOSPRefactorModel $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SessionName $SessionName
#$SessionName = Set-K2SmOSPAutoResolve $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SessionName $SessionName
#Set-K2SmODeployPackage -SessionName $SessionName
#Get-K2SmOSPCheckDeploymentStatus -SessionName $SessionName

#check status
# need logic to keep checking
# need a way to determing when the deployment has actually finished



#return

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

$SharePointAppsConfig = $config.Environment.SharePoint
foreach($SPAppConfig in $SharePointAppsConfig.App)
{

    # install K2 SharePoint apps or Appify lists and libraries
    
    Write-Host -ForegroundColor Yellow "STARTING: K2 SharePoint apps or Appify lists and libraries"

    # Get SPWeb - verify it exists
    $SPWeb = Get-SPWeb $SPAppConfig.SiteUrl

    if ($SPWeb -eq $null) {
        
        Write-Host -ForegroundColor Red "Site doesn't exist. Stepping over."
        continue
    }

    [string]$SPWebName = $SPWeb.Name
    if($SPWebName -eq "" -or $SPWebName -eq $null) {
        $SPWebName = $SPAppConfig.SiteUrl.Replace("https://", "").Replace("http://", "").Replace("/", "_").Replace(".", "_")
    }

    # Check if list exists - create if defined
    $List = $null
    $List = Get-K2SPList -SPWeb $SPWeb -ListName $SPAppConfig.ListName

    if ($SPAppConfig.Create -ne $null -and $List -eq $null) {
        if($SPAppConfig.Create.Type.ToLower() -eq "list") {
            
            New-K2SPList -SPWeb $SPWeb -Library $SPAppConfig.Create.List 
            $List = Get-K2SPList -SPWeb $SPWeb -ListName $SPAppConfig.ListName
            Add-K2DataToList -SPWeb $SPWeb -Library $SPAppConfig.Create.List -List $List
            $List = $null

        } else {
            #assume library
            New-K2SPList -SPWeb $SPWeb -Library $SPAppConfig.Create.List 
            $List = Get-K2SPList -SPWeb $SPWeb -ListName $SPAppConfig.ListName
            New-K2EnableDocumentType -SPWeb $SPWeb -List $List
            Add-K2DocumentsToLibrary -SPWeb $SPWeb -Library $SPAppConfig.Create.List -List $List
            $List = $null
        }
    } 

    if ($SPAppConfig.Create -eq $null -and $List -eq $null) {
        Write-Host -ForegroundColor Red "List doesn't exist. You need to create it for this to work. Stepping over."
        continue
    }

    $List = Get-K2SPList -SPWeb $SPWeb -ListName $SPAppConfig.ListName

    if ($SPAppConfig.Action.InnerText.ToLower() -eq "appify") {
        $SrcUrl = $SPAppConfig.BaseUrl + $List.DefaultViewUrl
        Set-K2SmOSPGenerateK2ArtifactsOnList -SiteUrl $SPAppConfig.SiteUrl -SiteName $SPWebName -ListName $SPAppConfig.ListName -ListId $List.ID -SourceUrl $SrcUrl -GenerateSmartForms $SPAppConfig.Action.GenerateSmartForms -SetFormsUrl $SPAppConfig.Action.GenerateSmartForms -GenerateReports $SPAppConfig.Action.GenerateReports
    }

    if ($SPAppConfig.Action.InnerText.ToLower() -eq "deploy") {

        $PackagePath = $ScriptPath+$SPAppConfig.Package

        if ($SPWeb.Name -eq "") {

        }

        $SessionName = Deploy-K2SharePointPackage -SiteUrl $SPAppConfig.SiteUrl -SiteName $SPWebName -ListName $SPAppConfig.ListName -ListId $List.ID -PackagePath $PackagePath
        
        if ($SessionName -eq "") {
            $jjk = 99
        }
    
        $counter = 1;
        $maximum = 10;
        $sleeptime = 30;
        [bool]$IsDeployed = $false;
        Write-Host -ForegroundColor White "Deploying." -NoNewline;
        while ($IsDeployed -eq $false -and ($counter -lt $maximum))
        {
            Write-Host -ForegroundColor White "." -NoNewline;
            sleep $sleeptime;
            $counter++;

            $DeployStatus = Get-K2SmOSPCheckDeploymentStatus -SessionName $SessionName
            if ($DeployStatus -eq "DEPLOYED") {
                $IsDeployed = $true
            }            

        }
        
        if ($IsDeployed -eq $true) {
            Write-Host ""
            Close-K2SmOSPDeploymentSession -SessionName $SessionName
            Write-Host -ForegroundColor White "Deployment session " $SessionName " is closed" 
        }    
    
    }

    Write-Host -ForegroundColor Green "FINISHED: K2 SharePoint apps or Appify lists and libraries"
    
    $SPWeb = $null
    $List = $null

}



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
            New-K2WorkflowGroupPermission -Workflow $Workflow.Name -GroupFQN $WorkflowPermission.FQN -Admin $WorkflowPermission.Admin -Start $WorkflowPermission.Start -View $WorkflowPermission.View -ViewParticipate $WorkflowPermission.ViewParticipate -ServerEvent $WorkflowPermission.ServerEvent
        }
        else
        {
            New-K2WorkflowUserPermission $Workflow.Name -UserFQN $WorkflowPermission.FQN -Admin $WorkflowPermission.Admin -Start $WorkflowPermission.Start -View $WorkflowPermission.View -ViewParticipate $WorkflowPermission.ViewParticipate -ServerEvent $WorkflowPermission.ServerEvent
        }
    }
}

# CONFIGURE ROLES
$RolesConfig = $config.Environment.PostDeploy.Roles
foreach($Role in $RolesConfig.Role)
{
    if ($Role.DefaultFQN -ne $null -and $Role.DefaulTyp -ne $null) {
    # If there's a DefaultFQN it's assumed that it's a new role that needs to be created. If the role happens to already exists nothing will happen
        New-K2Role -Name $Role.Name -DefaultRoleMember $Role.DefaultFQN -DefaultRoleMemberType $Role.DefaultType
    }
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

