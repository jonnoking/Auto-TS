
# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue


# CREDS?
$portalUrl = "https://portal.denallix.com/sites/jk1"
$portalName = "JK1"
$portalDescription = "A site for teams to quickly organize, author, and share information." 
$ownerAlias = "DENALLIX\Administrator"
$secondaryOwnerAlias = "DENALLIX\SPWebService" 

#Check if Site Collection Exists
$SPExists = (Get-SPSite $portalUrl -ErrorAction SilentlyContinue) -ne $null
#Write-Output($SPExists);


if ($SPExists)
{
    Write-Output "Site Collection already exists"
    return
}

# Create the Portal site collection
New-SPSite -Url $portalUrl -Name $portalName -Description $portalDescription -OwnerAlias $ownerAlias -SecondaryOwnerAlias $secondaryOwnerAlias -Template (Get-SPWebTemplate "STS#0")

# Create the Default Groups (Visitor, Member, and Owners)
$web = Get-SPWeb $portalUrl
$web.CreateDefaultAssociatedGroups($ownerAlias, $ownerAlias, "")
# Enable the OpenInClient feature
Enable-SPFeature -Identity OpenInClient -Url $portalUrl
# Add Everyone to Members
$user = $web.EnsureUser("C:0(.s|true")
$group = $web.SiteGroups.GetByName($portalName+" Members")
$group.AddUser($user)
$web.Update()


#Remove-SPSite -Identity $portalUrl -GradualDelete -Confirm:$false



#--------------------------------------------#
#Create Sites

#$SiteExists = (Get-SPWeb $portalUrl
$siteUrl = $portalUrl + "/HR"
Remove-SPWeb -Identity $siteUrl -Confirm:$false

$siteName = "Human Resources"
$siteDescription = "Human Resources"
Write-Output $siteUrl
$newSite = New-SPWeb -Url $siteUrl -Name $siteName -Description $siteDescription -Template (Get-SPWebTemplate "STS#0") -AddToQuickLaunch:$true -AddToTopNav:$true -UseParentTopNav:$true -UniquePermissions:$false -Language 1033



#--------------------------------------------#
#Create Document Library
$libName = "Demo Lib1"
$libDesc = "Demo Lib1"
$newSite.Lists.Add($libName, $libDesc, [Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary);
$newSite.Update();

$z = $siteUrl + "/" + $libName
Write-Output $z
Write-Output $newSite.ID

#customize library
#$lib = $newSite.GetList($z)

$lib = $newSite.Lists[$libName]
$regionCol = "<Field Type='Text' DisplayName='Region' Required='FALSE' MaxLength='255' StaticName='Region' Name='Region'/>"
$lib.Fields.AddFieldAsXml($regionCol,$true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
$lib.Update();

#add content to library & set metadata
$tFile = "C:\Resources\Samples\Vendor Contract.docx"
$File = Get-ChildItem $tFile
$FileName = $tFile.Substring($tFile.LastIndexOf("\")+1) 

$F = $newSite.GetFolder($libName);
$FF = $F.Files

$SPFile = $FF.Add($libName+"/"+$FileName, $File.OpenRead(),$false)
$SPFile.Item["Region"] = "Bellevue"
$SPFile.Item.Update()


#--------------------------------------------#
#Create List - Calendar

$calName = "Team Calendar"
$calDesc = "Team Calendar"
$newSite.Lists.Add($calName, $calDesc, [Microsoft.SharePoint.SPListTemplateType]::Events)
$newSite.Update()

$cal = $newSite.Lists[$calName]
$spItem = $cal.AddItem()

$spItem["Title"] = "Jonno"
$spItem["Location"] = "Bellevue"
$spItem["Start Time"] = "2015-06-06 13:00"
$spItem["End Time"] = "2015-06-06 14:00"
$spItem["Description"] = "yo"
$spItem.Update()


#foreach($c in $cal.Fields){
#Write-Output $c.Title
#}









