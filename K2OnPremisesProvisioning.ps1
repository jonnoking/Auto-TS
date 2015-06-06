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

# CUSTOMIZE PARENT SITE - LISTS
$SCLists = $config.SelectNodes("/Environment/SiteCollection/Lists")

foreach($Library in $SCLists.List) {    

    $SCS.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
    $SCS.Update();

    $lib = $SCS.Lists[$Library.Name]

    # CUSTOMIZE LIBRARY
    foreach($Field in $Library.CustomFields.Field) {

        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");
            $LookupList = $SCS.Lists[$LookupListName]
            $LookupListId = "{" +$LookupList.ID + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }

        $regionCol = $Field.OuterXml
        $lib.Fields.AddFieldAsXml($regionCol, $true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
        $lib.Update();
    }


    $ListData = $Library.ListData
    foreach($ItemData in $ListData.Item) {

        $spItem = $lib.AddItem()

        foreach($ItemField in $ItemData.Field) {
            $spItem[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
        }
        
        $spItem.Update()
    }

}


# CUSTOMIZE PARENT SITE - LIBRARIES
$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Libraries")

foreach($Library in $SCLibraries.Library) {    
    $SCS.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
    $SCS.Update();

    $lib = $SCS.Lists[$Library.Name]

    # CUSTOMIZE LIBRARY
    foreach($Field in $Library.CustomFields.Field) {
        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");
            $LookupList = $SCS.Lists[$LookupListName]
            $LookupListId = "{" +$LookupList.ID + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }
        $regionCol = $Field.OuterXml
        $lib.Fields.AddFieldAsXml($regionCol, $true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
        $lib.Update();
    }

    $ListData = $Library.ListData
    foreach($ItemData in $ListData.Item) {

        $spItem = $lib.AddItem()

        foreach($ItemField in $ItemData.Field) {
            $spItem[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
        }
        
        $spItem.Update()
    }

}


#REGION Create Sites
# CUSTOMIZE SITE - SITES
$SCSites = $config.SelectNodes("/Environment/SiteCollection/Sites")

foreach($Site in $SCSites.Site) {

    $SiteUrl = $SCUrl + $Site.Name
    #Remove-SPWeb -Identity $SiteUrl -Confirm:$false

    Write-Output $siteUrl
    $NewSite = New-SPWeb -Url $SiteUrl -Name $Site.Name -Description $Site.Description -Template (Get-SPWebTemplate $Site.Template) -AddToQuickLaunch:$true -AddToTopNav:$true -UseParentTopNav:$true -UniquePermissions:$false -Language $Site.Language


    # CUSTOMIZE SUB SITE - LISTS
    $SCLists = $config.SelectNodes("/Environment/SiteCollection/Lists")

    foreach($Library in $SCLists.List) {    

        $NewSite.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
        $NewSite.Update();

        $lib = $NewSite.Lists[$Library.Name]

        # CUSTOMIZE LIBRARY
        foreach($Field in $Library.CustomFields.Field) {
        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");
            $LookupList = $SCS.Lists[$LookupListName]
            $LookupListId = "{" +$LookupList.ID + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }
            $regionCol = $Field.OuterXml
            $lib.Fields.AddFieldAsXml($regionCol, $true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
            $lib.Update();
        }


        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            $spItem = $lib.AddItem()

            foreach($ItemField in $ItemData.Field) {
                $spItem[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
            }
        
            $spItem.Update()
        }

    }

    # CUSTOMIZE SUB SITE - LIBRARIES
    $SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Libraries")

    foreach($Library in $SCLibraries.Library) {    
        $NewSite.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
        $NewSite.Update();

        $lib = $NewSite.Lists[$Library.Name]

        # CUSTOMIZE LIBRARY
        foreach($Field in $Library.CustomFields.Field) {
        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");
            $LookupList = $SCS.Lists[$LookupListName]
            $LookupListId = "{" +$LookupList.ID + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }
            $regionCol = $Field.OuterXml
            $lib.Fields.AddFieldAsXml($regionCol, $true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
            $lib.Update();
        }

        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            $spItem = $lib.AddItem()

            foreach($ItemField in $ItemData.Field) {
                $spItem[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
            }
        
            $spItem.Update()
        }

    }

}
#ENDREGION Create Sites
