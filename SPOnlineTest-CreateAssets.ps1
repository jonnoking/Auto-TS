# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
#Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# Paths to SDK. Please verify location on your computer.    
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"     
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

# Import Modules
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# ADD CSOM FUNCTIONS
. .\Development\Auto-TS\CSOMFunctions.ps1

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
#$SC = Get-SPOSite $SCUrl -Detailed

Disconnect-SPOService



$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SCUrl)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($TenantAdmin, $TenantAdminPwdSecure)
$Context.Credentials = $Creds




$K2SettingsList = Get-K2SPList -SPWeb $web -ListName "K2 Settings"

    # ADD CONTENT TO EXISTING LIBRARIES e.g. SITE ASSETS, SITE PAGES
    $Library = $config.SelectNodes("/Environment/SiteCollection/Existing/Lists/List[Name='K2 Settings']")

	$List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name

	if ($List-eq $null) {
        Write-Host -ForegroundColor Red "Specified existing library $Library.Name doesn't exist. Stepping over."
        continue
	}

	Add-K2DataToList -SPWeb $web -Library $Library -List $List


return




$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Libraries")

foreach($Library in $SCLibraries.Library) {    

    $List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name
    
    if ($List -ne $null) {
        Write-Host -ForegroundColor Red "Site $Library.Name already exists. Stepping over."
        continue
    }

   	New-K2SPList -SPWeb $Context.Web -Library $Library
 
    $List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name

	New-K2EnableDocumentType -List $List

	Add-K2DocumentsToLibrary -SPWeb $Context.Web -Library $Library -List $List

    $List = $null
}













return



function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.PSScriptRoot)
    {
        $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        Split-Path $Invocation.MyCommand.Path
    }
    else
    {
        $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
    }
}

function Log-ToFile($msg) {
    $cwd = Get-ScriptDirectory
    $d = Get-Date
    $logfile = $cwd + "\logfile.log"

    $t = $d.ToString("yyyy-MM-dd HH:mm:ss") + " " + $msg

    Add-Content $logfile $t
    Write-Host -ForegroundColor Green $t

}

Log-ToFile("hey hey")
return


$csom = "." + $cmd + "\CSOMFunctions.ps1"
. $csom



#Write-Host $invocation
return

Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

$user = "jonno@k2loud.onmicrosoft.com"
$userpwd = "K2nkK2007"
$userpwdsecure = convertto-securestring "K2nkK2007" -AsPlainText -force
$siteUrl = "https://k2loud.sharepoint.com"
$steAdminUrl = "https://k2loud-admin.sharepoint.com/"

$newSCName = "Jonno 1"
$newSCDesc = "Jonno 1"
$newSCUrl = $siteUrl + "/sites/" + $newSCName.Replace(" ", "")

$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $userpwdsecure
Connect-SPOService -Url https://k2loud-admin.sharepoint.com/ -Credential $creds



#Check if Site Collection Exists
$SPExists = $null
$SC = $null
try {
    $SC = Get-SPOSite $newSCUrl
    $SPExists = $true;
} catch {
    $SPExists = $false;
    return
}
 
#Write-Output($SPExists);


if ($SPExists -ne $null -and $SPExists)
{
    Write-Output "Site Collection already exists"
} else {
   Write-Output "Site Collection doesn't exist"
    return 
}

Disconnect-SPOService

$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($newSCUrl)
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($user, $userpwdsecure)

$ctx.Credentials = $credentials

$rootWeb = $ctx.Web
$sites = $rootWeb.Webs








