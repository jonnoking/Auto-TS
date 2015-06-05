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








