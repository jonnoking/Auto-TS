# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue


# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfig.xml


# Get Base Settings
$BaseUrl = $config.Environment.Settings.SiteBaseUrl


# Create Site Collection

$SCName = $config.Environment.SiteCollection.Name
$SCDescription = $config.Environment.SiteCollection.Description
$SCUrl = $BaseUrl + "/sites/" + $SCName.Replace(" ", "")
$SCTemplate = $config.Environment.SiteCollection.Template
$SCOwner = $config.Environment.SiteCollection.Owner
$SCSecondaryOwner = $config.Environment.SiteCollection.SecoondaryOwner
$SCLanguage = $config.Environment.SiteCollection.Language


$SPExists = (Get-SPSite $SCUrl -ErrorAction SilentlyContinue) -ne $null


if ($SPExists)
{
    Write-Host -ForegroundColor Red "Site Collection already exists"
    Write-Host -ForegroundColor Red "SCRIPTED HAS STOPPED"
    Remove-SPSite -Identity $SCUrl -GradualDelete -Confirm:$false
    return
}

# CREATE SITE COLLECTION
$NewSC = New-SPSite -Url $SCUrl -Name $SCName -Description $SCDescription -OwnerAlias $SCOwner -SecondaryOwnerAlias $SCSecondaryOwner -Template (Get-SPWebTemplate $SCTemplate)

# Create the Default Groups (Visitor, Member, and Owners)
$SCweb = Get-SPWeb $SCUrl
$SCweb.CreateDefaultAssociatedGroups($SCOwner, $SCOwner, "")
# Enable the OpenInClient feature
Enable-SPFeature -Identity OpenInClient -Url $SCUrl
# Add Everyone to Members
$SCAllUsers = $SCweb.EnsureUser("C:0(.s|true")
$SCgroup = $SCweb.SiteGroups.GetByName($SCName+" Members")
$SCgroup.AddUser($SCAllUsers)
$SCweb.Update()


Write-Host -ForegroundColor Green "Site Collection Created"

$SCS = Get-SPWeb -Identity $SCUrl

# CUSTOMIZE PARENT SITE
[xml]$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Libraries")

foreach($Library in $SCLibraries.Library) {    
    $SCS.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary);
    $SCS.Update();


    # CUSTOMIZE LIST
    foreach($Field in $Library.CustomFields.Field) {

        $lib = $SCS.Lists[$Library.Name]
        $regionCol = $Field.OuterXml
        $lib.Fields.AddFieldAsXml($regionCol, $true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
        $lib.Update();

    }


}




