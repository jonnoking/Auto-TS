# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
#Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# Paths to SDK. Please verify location on your computer.    
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"     
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

# Import Modules
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
Import-Module SPOMod


# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfig.xml


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


$AdminCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $TenantAdmin, $userpwdsecure
Connect-SPOService -Url https://k2loud-admin.sharepoint.com/ -Credential $AdminCreds


#Check if Site Collection Exists
$SCExists = $null
$SC = $null
try {
    $SC = Get-SPOSite $newSCUrl
    $SPExists = $true;
} catch {
    $SPExists = $false;
    return
} 

if ($SPExists -ne $null -and $SPExists)
{
    Write-Host -ForegroundColor Red "Site Collection already exists"

    #Remove-SPOSite $SCUrl -Confirm:$false
    #Remove-SPODeletedSite -Identity $SCUrl -Confirm:$false
    #Write-Host -ForegroundColor Red "Site Collection deleted"

    return 

} else {
   Write-Host -ForegroundColor Red "Site Collection doesn't exist"
}


# CREATE SITE COLLECTION

New-SPOSite -Url $SCUrl -Title $SCName -Owner $TenantAdmin -Template $SCTemplate -StorageQuota $SCQuota

# get site collection
$SC = Get-SPOSite $SCUrl -Detailed

# Add Everyone to Members group
$SCGroupMembers = $SCName + " Members"
Add-SPOUser -Site $SC -Group $SCGroupMembers -LoginName "C:0(.s|true"

Disconnect-SPOService

Write-Host -ForegroundColor Green "Site Collection Created"


$SCS = Get-SPWeb -Identity $SCUrl

# CUSTOMIZE PARENT SITE - LISTS
$SCLists = $config.SelectNodes("/Environment/SiteCollection/Lists")

foreach($Library in $SCLists.List) {    

}

