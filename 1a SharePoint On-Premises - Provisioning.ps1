# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition


# Load SP Snapin
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# ADD CSOM FUNCTIONS
. $ScriptPath"\1z SharePoint On-Premises - Functions.ps1"


# Load Config
[xml]$config = Get-Content $ScriptPath"\1 SharePoint On-Premises - Config.xml"


# Get Base Settings
$BaseUrl = $config.Environment.Settings.SiteBaseUrl


# Create Site Collection

$SCName = $config.Environment.SiteCollection.Name
$SCDescription = $config.Environment.SiteCollection.Description
$SCUrlName = $config.Environment.SiteCollection.UrlName
$SCUrl = $BaseUrl + "/sites/" + $SCUrlName
$SCTemplate = $config.Environment.SiteCollection.Template
$SCOwner = $config.Environment.SiteCollection.Owner
$SCSecondaryOwner = $config.Environment.SiteCollection.SecoondaryOwner
$SCLanguage = $config.Environment.SiteCollection.Language

$SCExists = $config.Environment.SiteCollection.GetAttribute("Exists").ToLower()

#Check if Site Collection Already exists
$SPExists = (Get-SPSite $SCUrl -ErrorAction SilentlyContinue) -ne $null
if ($SPExists -and $SCExists -ne "true")
{
    Write-Host -ForegroundColor Red "Site Collection already exists and you're configuration file specifies not to overwrite it"
    $P = 'Delete the existing Site Collection at: ' + $SCUrl + ' [Y|N]?'
    $Delete = Read-Host -Prompt $P
    
    # Popup Prompt
    #https://technet.microsoft.com/en-us/library/Ff730941.aspx

    # Popup Prompt
    #[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
    #$computer = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername")



    if ($Delete.ToLower() -eq "y" -or $Delete.ToLower() -eq "yes") {

        Remove-SPSite -Identity $SCUrl -GradualDelete -Confirm:$false
        Write-Host -ForegroundColor Red "Site Collection has been deleted"
    }

    Write-Host -ForegroundColor Red "SCRIPTED HAS STOPPED"
    return
}
#else
#{
#	Write-Host -ForegroundColor Red "Site Collection does not exist"
#}


# If site collection doesn't exist then create it
if (!$SPExists)
{

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

}



$SCS = Get-SPWeb -Identity $SCUrl

# CUSTOMIZE PARENT SITE - LISTS
$SCLists = $config.SelectNodes("/Environment/SiteCollection/Lists")

foreach($Library in $SCLists.List) {
    $List = Get-K2SPList -SPWeb $SCS -ListName $Library.Name
    if ($List -ne $null) {
            Write-Host -ForegroundColor Red "List" $Library.Name "already exists. Stepping over."
            continue
    }    
    New-K2SPList -SPWeb $SCS -Library $Library 
    $List = Get-K2SPList -SPWeb $SCS -ListName $Library.Name
    Add-K2DataToList -SPWeb $SCS -Library $Library -List $List
    $List = $null
}


# CUSTOMIZE PARENT SITE - LIBRARIES
$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Libraries")

foreach($Library in $SCLibraries.Library) {    
    $List = Get-K2SPList -SPWeb $SCS -ListName $Library.Name
    if ($List -ne $null) {
            Write-Host -ForegroundColor Red "Library" $Library.Name "already exists. Stepping over."
            continue
    }    
    New-K2SPList -SPWeb $SCS -Library $Library 
    $List = Get-K2SPList -SPWeb $SCS -ListName $Library.Name
    New-K2EnableDocumentType -SPWeb $SCS -List $List
    Add-K2DocumentsToLibrary -SPWeb $SCS -Library $Library -List $List
    $List = $null
}

# REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING ALL TOP LEVEL SITE ASSETS
    Write-Host -ForegroundColor Blue "Removing quicklaunch navigation from " $SCweb.Name
    Set-K2TrimMenu -SPWeb $SCweb


# ADD CONTENT TO EXISTING LIBRARIES e.g. SITE ASSETS, SITE PAGES
$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Existing/Libraries")

foreach($Library in $SCLibraries.Library) {    

	$List = Get-K2SPList -SPWeb $SCweb -ListName $Library.Name

	if ($List-eq $null) {
        Write-Host -ForegroundColor Red "Specified existing library $Library.Name doesn't exist. Stepping over."
        continue
	}

	Add-K2DocumentsToLibrary -SPWeb $SCweb -Library $Library -List $List

    $List = $null
}


# MODIFY THE SITE LOGO
$LongFileName = $config.SelectSingleNode("/Environment/SiteCollection/Existing/Libraries/Library[Name='Site Assets']/ListData/Item[1]/Field[@Property='File']").InnerText
Set-K2SPSiteLogo -LongFileName $LongFileName -SPWeb $SCweb -SCUrlName $SCUrlName


#REGION Create Sites
# CUSTOMIZE SITE - SITES
$SCSites = $config.SelectNodes("/Environment/SiteCollection/Sites")

foreach($Site in $SCSites.Site) {
    Write-Host -ForegroundColor Blue "Creating Site " $Site.Name
    $SiteUrl = $SCUrl + "/" + $Site.UrlName

    # Check if sub site exists and step over if it does
    #$SiteExists = (Get-SPWeb $SiteUrl -ErrorAction SilentlyContinue) -ne $null
    #if($SiteExists) {
    #    Write-Host -ForegroundColor Red "Site $SiteUrl already exists. Stepping over."
    #    continue
    #}


    # Get Site - if it doesn't exist then create it
    $NewSubSite = Get-SPWeb $SiteUrl -ErrorAction SilentlyContinue #) -ne $null
    if ($NewSubSite -eq $null -or $NewSubSite -eq $false) {
        $NewSubSite = New-SPWeb -Url $SiteUrl -Name $Site.Name -Description $Site.Description -Template (Get-SPWebTemplate $Site.Template) -AddToQuickLaunch:$true -AddToTopNav:$true -UseParentTopNav:$true -UniquePermissions:$false -Language $Site.Language
    }


    # CUSTOMIZE SUB SITE - LISTS
    $SCLists = $Site.Lists
    foreach($Library in $SCLists.List) {   
        $List = Get-K2SPList -SPWeb $NewSubSite -ListName $Library.Name
        if ($List -ne $null) {
                Write-Host -ForegroundColor Red "List" $Library.Name "already exists. Stepping over."
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
                Write-Host -ForegroundColor Red "Library" $Library.Name "already exists. Stepping over."
                continue
        }    
        New-K2SPList -SPWeb $NewSubSite -Library $Library 
        $List = Get-K2SPList -SPWeb $NewSubSite -ListName $Library.Name
        New-K2EnableDocumentType -SPWeb $SCS -List $List
        Add-K2DocumentsToLibrary -SPWeb $NewSubSite -Library $Library -List $List
        $List = $null

    }
    
    # REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING EACH SUB-SITE
    Write-Host -ForegroundColor Blue "Removing quicklaunch navigation from " $Site.Name
    Set-K2TrimMenu -SPWeb $NewSubSite

    

}
#ENDREGION Create Sites
