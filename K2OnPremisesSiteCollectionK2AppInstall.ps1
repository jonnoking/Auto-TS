
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}


# Get app from Catalog - Appit or blackpearl
    # If not in catalog - upload from location x - prompt/fail
# Import package
# recurse through sites and install app

# launch browser for config - have to go to app permissions to TRUST the app - this will then take you to reg settings


# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfig.xml


# Get Base Settings
$BaseUrl = $config.Environment.Settings.SiteBaseUrl


# Get Site Collection

$SCName = $config.Environment.SiteCollection.Name
$SCDescription = $config.Environment.SiteCollection.Description
$SCUrlName = $config.Environment.SiteCollection.UrlName
$SCUrl = $BaseUrl + "/sites/" + $SCUrlName
$SCTemplate = $config.Environment.SiteCollection.Template
$SCOwner = $config.Environment.SiteCollection.Owner
$SCSecondaryOwner = $config.Environment.SiteCollection.SecoondaryOwner
$SCLanguage = $config.Environment.SiteCollection.Language


$SPExists = (Get-SPSite $SCUrl -ErrorAction SilentlyContinue) -ne $null

$err = $null
if (!$SPExists)
{
    Write-Host -ForegroundColor Red "Site Collection does not exists"
    Write-Host -ForegroundColor Red "SCRIPTED HAS STOPPED"
    return
}
$SC = Get-SPSite $SCUrl
$AppName = "K2 blackpearl for SharePoint" #Appit app name?
$newPackagePath = "C:\Program Files (x86)\K2 blackpearl\K2 for SharePoint 2013 Setup\SharePoint App\K2 for SharePoint.app"

$SCS = Get-SPWebApplication -Identity "https://portal.denallix.com"
# Get App
$appInstance = Get-SPAppInstance -Web "https://portal.denallix.com" | where-object {$_.Title -eq $AppName}
if ($err) 
{
    Write-Host -ForegroundColor Yellow "An error occurred getting app"
    throw $err;
}

if ($false)
{


#removes app from site collection and sub sites
foreach($web in $SC.AllWebs)
{
    if(!$web.IsAppWeb) {    

        $appInstance = Get-SPAppInstance -Web $web.Url | where-object {$_.Title -eq $AppName};
        Uninstall-SPAppInstance –Identity $appInstance -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err;
        if ($err) 
        {
        Write-Host -ForegroundColor White "- An error occured during app uninstallation !";
        throw $err;
        }
    }
}
    return

}


$updatedApp = Import-SPAppPackage -Path $newPackagePath -Site $SCUrl -Source CorporateCatalog -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err;

if ($err -or ($updatedApp -eq $null)) 
{
    Write-Host -ForegroundColor Yellow "An error occurred during app import"
    throw $err;
}
#Install-SPApp -Web $SCUrl -Identity $updatedApp # unncessary as top site will be part of SC.AllWebs


foreach($web in $SC.AllWebs)
{
    if(!$web.IsAppWeb) {    
        Install-SPApp -Web $web.Url -Identity $updatedApp
    }
}
$appInstance = Get-SPAppInstance -Web $SC.Url | where-object {$_.Title -eq $AppName}



$url = $SC.Url +"/_layouts/15/start.aspx#/_layouts/15/AppInv.aspx?Manage=1&AppInstanceId=" + $appInstance.Id +"&Source=" + [System.Web.HttpUtility]::UrlEncode($SC.Url + "/_layouts/15/viewlsts.aspx")
$ie = New-Object -com internetexplorer.application; 
$ie.visible = $true; 
$ie.navigate($url);


return 


#removes app from site collection and sub sites
foreach($web in $SC.AllWebs)
{
    if(!$web.IsAppWeb) {    

        $appInstance = Get-SPAppInstance -Web $web.Url | where-object {$_.Title -eq $AppName};
        Uninstall-SPAppInstance –Identity $appInstance -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err;
        if ($err) 
        {
        Write-Host -ForegroundColor White "- An error occured during app uninstallation !";
        throw $err;
        }
    }
}



