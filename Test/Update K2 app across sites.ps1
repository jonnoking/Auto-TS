
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

$oldAppTitle = "K2 for SharePoint"
$newAppTitle = "K2 blackpearl for SharePoint"
$rootUrl = Read-Host "What is your Web Application's Root Url?"
# This version number is for 4.6.9
$newVersion = "4.4120.5.100"		
#$newPackagePath = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition) + "\K2 for SharePoint.app"
$newPackagePath = "C:\Program Files (x86)\K2 blackpearl\K2 for SharePoint 2013 Setup\K2 for SharePoint.app"

Function UpdateApp ($appInstance, $appV2, $web)
{
    $app = Update-SPAppInstance –Identity $appInstance –App $appV2 -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err;

    if ($err) {
        Write-Host -ForegroundColor Red "An error occurred during app update"
        throw $err;
    }

    #$AppName = $app.Title;
    Write-Host -ForegroundColor White "App registered, please wait while it updates..."
    $newAppInstance = Get-SPAppInstance -Web $web | where-object {$_.Title -eq $newAppTitle};
    $counter = 1;
    $maximum = 150;
    $sleeptime = 2;
    Write-Host -ForegroundColor White "Progress ." -NoNewline;
    while (($newAppInstance.Status -eq ([Microsoft.SharePoint.Administration.SPAppInstanceStatus]::Upgrading)) -and ($counter -lt $maximum))
    {
        Write-Host -ForegroundColor White "." -NoNewline;
        sleep $sleeptime;
        $counter++;
        $newAppInstance = Get-SPAppInstance -Web $web | where-object {$_.Title -eq $newAppTitle} 
    }
    Write-Host -ForegroundColor White ".";

    Write-Host "App updated successfully";
}


$webApp = Get-SPWebApplication $rootUrl

# Import new version
Write-Host "Uploading latest package to Root"
$updatedApp = Import-SPAppPackage -Path $newPackagePath -Site $rootUrl -Source ObjectModel -Confirm:$false -ErrorAction SilentlyContinue -ErrorVariable err;

if ($err -or ($updatedApp -eq $null)) 
{
    Write-Host -ForegroundColor Yellow "An error occurred during app import"
    throw $err;
}
else
{
    foreach($site in $webApp.Sites)
    {
        foreach($web in $site.AllWebs)
        {
            $appInstance = Get-SPAppInstance -Web $web.Url | Where{$_.Title -eq $oldAppTitle}

            if($appInstance -ne $null)

            {
                #Write-Host $web.Url -BackgroundColor Green
                #Write-Host $appInstance.App.VersionString -BackgroundColor Cyan
                if($appInstance.App.VersionString -ne $newVersion)
                {
                    Write-Host "Site '" -NoNewline
                    Write-Host $web.Url -NoNewline
                    Write-Host "' has version '" -NoNewline 
                    Write-Host $appInstance.App.VersionString -NoNewline 
                    Write-Host "' installed, attempting to update..."

                    UpdateApp -appInstance $appInstance -appV2 $updatedApp -web $web
                    Write-Host ""
               
                }
            }
        }
    }
}