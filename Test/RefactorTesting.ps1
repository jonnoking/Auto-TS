# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
#Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# Paths to SDK. Please verify location on your computer.    
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"     
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

# Import Modules
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
#Import-Module SPOMod

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
Connect-SPOService -Url https://k2loud-admin.sharepoint.com/ -Credential $AdminCreds


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

Disconnect-SPOService

[Microsoft.SharePoint.Client.ClientContext]$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SCUrl)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($TenantAdmin, $TenantAdminPwdSecure)
$Context.Credentials = $Creds


# CUSTOMIZE SITE - SITES
$SCSites = $config.SelectNodes("/Environment/SiteCollection/Sites")

foreach($Site in $SCSites.Site) {

    $NewSubSite = Get-K2SPWeb -SPWeb $Context.Web -SiteName $Site.Name

    if ($NewSubSite -eq $null) {
	    New-K2CreateSite -SPWeb $Context.Web -Site $Site
        $NewSubSite = Get-K2SPWeb -SPWeb $Context.Web -SiteName $Site.Name

    } 
    
    # CUSTOMIZE SUB SITE - LISTS
    $SCLists = $Site.Lists
    foreach($Library in $SCLists.List) {    
	
		$List = Get-K2SPList -SPWeb $NewSubSite -ListName $Library.Name

        if ($List -ne $null) {
            Write-Host -ForegroundColor Red "Site $Library.Name already exists. Stepping over."
            continue
        }

        New-K2SPList -SPWeb $NewSubSite -Library $Library

        $List = Get-K2SPList -SPWeb $NewSubSite -ListName $Library.Name

		Add-K2DataToList -SPWeb $NewSubSite -Library $Library -List $List
        
        $List = $null	
    }


    # CUSTOMIZE SUB SITE - LIBRARIES
    $SCLibraries = $Site.Libraries
    foreach($Library in $SCLibraries.Library) {    

		$List = Get-K2SPList -SPWeb $NewSubSite -ListName $Library.Name

        if ($List -ne $null) {
            Write-Host -ForegroundColor Red "Site $Library.Name already exists. Stepping over."
            continue
        }

   		New-K2SPList -SPWeb $NewSubSite -Library $Library

        $List = Get-K2SPList -SPWeb $NewSubSite -ListName $Library.Name

		New-K2EnableDocumentType -List $List

		Add-K2DocumentsToLibrary -SPWeb $NewSubSite -Library $Library -List $List

        $List = $null	

    }

	Set-K2TrimMenu -SPWeb $NewSubSite

    # Reorganize Quick Launch

    # Update Pages

}



$Context.Dispose()

return



# ADD CONTENT TO EXISTING LIBRARIES e.g. SITE ASSETS, SITE PAGES
$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Existing/Libraries")

foreach($Library in $SCLibraries.Library) {    

	$List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name

	if ($List-eq $null) {
        Write-Host -ForegroundColor Red "Specified existing library $Library.Name doesn't exist. Stepping over."
        continue
	}

	Add-K2DocumentsToLibrary -SPWeb $Context.Web -Library $Library -List $List

    $List = $null
}

    # MODIFY THE SITE LOGO
    $LongFileName = $config.SelectSingleNode("/Environment/SiteCollection/Existing/Libraries/Library[Name='Site Assets']/ListData/Item[1]/Field[@Property='File']").InnerText
	Set-K2SPSiteLogo -LongFileName $LongFileName

    # REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING ALL TOP LEVEL SITE ASSETS
	Set-K2TrimMenu -SPWeb $Context.Web



# CUSTOMIZE PARENT SITE - LIBRARIES
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



$SCLists = $config.SelectNodes("/Environment/SiteCollection/Lists")

foreach($Library in $SCLists.List) {    

    $List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name

    if ($List -ne $null) {
        Write-Host -ForegroundColor Red "Site $Library.Name already exists. Stepping over."
        continue
    }

	New-K2SPList -SPWeb $Context.Web -Library $Library

    $List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name

    Add-K2DataToList -SPWeb $Context.Web -Library $Library -List $List

    $List = $null
}


