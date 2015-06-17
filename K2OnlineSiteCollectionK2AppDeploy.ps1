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
$SC = Get-SPOSite $SCUrl -Detailed

Disconnect-SPOService



$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SCUrl)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($TenantAdmin, $TenantAdminPwdSecure)
$Context.Credentials = $Creds

$AppName = "K2 blackpearl for SharePoint" #Appit app name?
$newPackagePath = "C:\Program Files (x86)\K2 blackpearl\K2 for SharePoint 2013 Setup\SharePoint Online\K2 for SharePoint.app"


$web = $Context.Web
$site = $Context.Site
$Context.Load($web)
$Context.Load($web.Webs)
$Context.Load($site)
$Context.ExecuteQuery()



    #assume no dev feature enabled - not great approach - might have to be done manually
    #$guiFeatureGuid = [System.Guid]"e374875e-06b6-11e0-b0fa-57f5dfd72085"
    #$site.Features.Add($guiFeatureGuid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None) 
    #$Context.ExecuteQuery() 

    Enable-K2SharePointFeature -SPWeb $Site -FeatureGuid "e374875e-06b6-11e0-b0fa-57f5dfd72085"

    Add-K2SideLoadApp -SPWeb $web -AppPath $newPackagePath
    
    foreach($w in $web.Webs) {
    
        Add-K2SideLoadApp -SPWeb $w -AppPath $newPackagePath

        # This doesn't work because the app install hasn't finished by the time this code has been reached. Either loop and wait for app to install or remove
        #Set-K2TrimMenuItem -SPWeb $w -MenuItem "Recent"

    }

    Disable-K2SharePointFeature -SPWeb $Site -FeatureGuid "e374875e-06b6-11e0-b0fa-57f5dfd72085"

    #$site.Features.Remove($guiFeatureGuid, $true) 
    #$Context.ExecuteQuery() 


    #clean up after enabling developer feature
    Set-K2TrimMenuItem -SPWeb $web -MenuItem "Apps in Testing"
    Set-K2TrimMenuItem -SPWeb $web -MenuItem "Samples"
    Set-K2TrimMenuItem -SPWeb $web -MenuItem "Developer Center"
    Set-K2TrimMenuItem -SPWeb $web -MenuItem "Recent"
    
    Delete-K2SPList -SPWeb $web -ListTitle "Apps in Testing"
    Delete-K2SPList -SPWeb $web -ListTitle "App Packages"

    #Set-K2WebHomePage -SPWeb $web -PageUrl "SitePages/Home.aspx"
    Set-K2WebHomePage -SPWeb $web -PageUrl "K2DemoPages/DemoPage1.aspx"


    #wiki homepage feature - 00bfea71-d8fe-4fec-8dad-01c19a6e4053
   

    #Navigate to Site Contents
    ## Mouse over app --> ... --> Permissions --> "click HERE to tust again"
    $SiteContentsUrl = $SC.Url + "/_layouts/15/start.aspx#/_layouts/15/viewlsts.aspx"
    $ie = New-Object -com internetexplorer.application; 
    $ie.visible = $true; 
    $ie.navigate($SiteContentsUrl);



    ##### K2 Settings list doesn't exist until the app has been trusted #####
    ##### Won't be able to automate on first install - maybe for updates #####

    # ADD CONTENT TO EXISTING LIBRARIES e.g. SITE ASSETS, SITE PAGES
    #$Library = $config.SelectNodes("/Environment/SiteCollection/Existing/Lists/List[Name='K2 Settings']")

	#$List = Get-K2SPList -SPWeb $Context.Web -ListName $Library.Name

	#if ($List-eq $null) {
    #    Write-Host -ForegroundColor Red "Specified existing library $Library.Name doesn't exist. Stepping over."
    #    continue
	#}

	#Add-K2DataToList -SPWeb $web -Library $Library -List $List

    #$List = $null

##########

    #https://k2loud.sharepoint.com/sites/jonnotech/_layouts/15/start.aspx#/_layouts/15/viewlsts.aspx


    ##### Until the app has been trusted this will show an error about not having permissions #####
    # Get top level site K2 App
    #$K2App = Get-K2AppWeb -SPWeb $Context.Web -AppTitle "K2 blackpearl for SharePoint"
    
    #$AppRegUrl = $K2App.Url + "/Pages/Registration.aspx?SPSiteURL=" + $SC.Url

    #$ie = New-Object -com internetexplorer.application; 
    #$ie.visible = $true; 
    #$ie.navigate($AppRegUrl);
