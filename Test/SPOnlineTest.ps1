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

# Delete Site Collection and remove from recycle bin
#Remove-SPOSite $newSCUrl -Confirm:$false
#Remove-SPODeletedSite -Identity $newSCUrl -Confirm:$false
#Disconnect-SPOService






#Check if Site Collection Exists
$SPExists = $null
$SC = $null
try {
    $SC = Get-SPOSite $newSCUrl
    $SPExists = $true;
} catch {
    $SPExists = $false;
}
 
#Write-Output($SPExists);


if ($SPExists -ne $null -and $SPExists)
{
    Write-Output "Site Collection already exists"
    return
} else {
   Write-Output "Site Collection doesn't exist"
 
}

# create site collection
New-SPOSite -Url $newSCUrl -Title $newSCName -Owner $user -Template "STS#0" -StorageQuota 100

# get site collection
$site = Get-SPOSite $newSCUrl -Detailed

# Add Everyone to Members group
$gpname = $newSCName + " Members"
Add-SPOUser -Site $site -Group $gpname -LoginName "C:0(.s|true"



Disconnect-SPOService
