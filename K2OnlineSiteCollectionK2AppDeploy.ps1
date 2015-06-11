# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
#Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# Paths to SDK. Please verify location on your computer.    
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"     
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

# Import Modules
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking


# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfigOnline.xml


# Get Base Settings
$BaseUrl = $config.Environment.Settings.SiteBaseUrl
$BaseAdminUrl = $config.Environment.Settings.SiteAdminUrl

# Get Credentials
$TenantAdmin = $config.Environment.Settings.TenantAdmin
$TenantAdminPwd = $config.Environment.Settings.TenantAdminPassword
$TenantAdminPwdSecure = convertto-securestring $TenantAdminPwd -AsPlainText -force


# Site Collection Settings

$SCName = $config.Environment.SiteCollection.Name
$SCDescription = $config.Environment.SiteCollection.Description
$SCUrlName = $config.Environment.SiteCollection.UrlName
$SCUrl = $BaseUrl + "/sites/" + $SCUrlName
$SCTemplate = $config.Environment.SiteCollection.Template
$SCOwner = $config.Environment.SiteCollection.Owner
$SCSecondaryOwner = $config.Environment.SiteCollection.SecoondaryOwner
$SCLanguage = $config.Environment.SiteCollection.Language
$SCQuota = $config.Environment.SiteCollection.Quota


$AdminCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $TenantAdmin, $TenantAdminPwdSecure
Connect-SPOService -Url $BaseAdminUrl -Credential $AdminCreds


#Check if Site Collection Exists
$SCExists = $null
$SC = $null
try {
    $SC = Get-SPOSite $SCUrl
    $SPExists = $true;
} catch {
    $SPExists = $false;
    
} 

if ($SPExists -ne $null -and $SPExists)
{
    Write-Host -ForegroundColor Red "Site Collection already exists"
} else {
   Write-Host -ForegroundColor Red "Site Collection doesn't exist"
    return 
}


# get site collection
$SC = Get-SPOSite $SCUrl -Detailed


Disconnect-SPOService

Write-Host -ForegroundColor Green "Site Collection Created"


$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SCUrl)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($TenantAdmin, $TenantAdminPwdSecure)
$Context.Credentials = $Creds

$AppName = "K2 blackpearl for SharePoint" #Appit app name?
$newPackagePath = "C:\Program Files (x86)\K2 blackpearl\K2 for SharePoint 2013 Setup\SharePoint Online\K2 for SharePoint.app"


$web = $Context.Web
$site = $Context.Site
$Context.Load($web)
$Context.Load($site)
$Context.ExecuteQuery()


    #assume no dev feature enabled - not great approach - might have to be done manually
    $guiFeatureGuid = [System.Guid]"e374875e-06b6-11e0-b0fa-57f5dfd72085"
    $site.Features.Add($guiFeatureGuid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None) 
    $Context.ExecuteQuery() 


$appIoStream = New-Object IO.FileStream($newPackagePath ,[System.IO.FileMode]::Open)
$appInstance = $web.LoadAndInstallApp($appIoStream) | Out-Null
$Context.ExecuteQuery()
Write-Host $appInstance.Id

$appIoStream.Dispose()
$Context.Dispose()


 