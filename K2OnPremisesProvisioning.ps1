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
$SCUrlName = $config.Environment.SiteCollection.UrlName
$SCUrl = $BaseUrl + "/sites/" + $SCUrlName
$SCTemplate = $config.Environment.SiteCollection.Template
$SCOwner = $config.Environment.SiteCollection.Owner
$SCSecondaryOwner = $config.Environment.SiteCollection.SecoondaryOwner
$SCLanguage = $config.Environment.SiteCollection.Language


$SPExists = (Get-SPSite $SCUrl -ErrorAction SilentlyContinue) -ne $null


if ($SPExists)
{
    Write-Host -ForegroundColor Red "Site Collection already exists"
    Remove-SPSite -Identity $SCUrl -GradualDelete -Confirm:$false
    Write-Host -ForegroundColor Red "SCRIPTED HAS STOPPED"
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
    $lib.OnQuickLaunch = $true;
    $lib.Update();

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
    $lib.OnQuickLaunch = $true;
    $lib.ContentTypesEnabled = $true
    #$lib.Update();

    $DocSet = $SCS.ContentTypes["Document Set"]
    $ct = $lib.ContentTypes.Add($DocSet)
    $lib.Update();

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

    # Upload File
    # Needs to allow for uploading to Document Sets - Check it exists, create if required, upload to Doc Set
        $spItem = $null
        
        foreach($ItemField in $ItemData.Field) {
            if($ItemField.GetAttribute("Property").ToLower() -eq "file") {

                # Assumes local file
                $LibFile = $ItemField.InnerText
                $File = Get-ChildItem $LibFile
                $LibFileName = $LibFile.Substring($LibFile.LastIndexOf("\")+1) 
                
                $LibFolder = $SCS.GetFolder($Library.Name);

                $LibFiles = $LibFolder.Files
                
                $spItem = $LibFiles.Add($Library.Name+"/"+$LibFileName, $File.OpenRead(),$false)
                break
            }
        }

        foreach($ItemField in $ItemData.Field) {
            if($ItemField.GetAttribute("Property").ToLower() -ne "file") {

                $spItem.Item[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
            }
        }

        $spItem.Item.Update()
    }

}


#REGION Create Sites
# CUSTOMIZE SITE - SITES
$SCSites = $config.SelectNodes("/Environment/SiteCollection/Sites")

foreach($Site in $SCSites.Site) {

    $SiteUrl = $SCUrl + "/" + $Site.UrlName
    #Remove-SPWeb -Identity $SiteUrl -Confirm:$false

    Write-Output $SiteUrl
    $NewSubSite = New-SPWeb -Url $SiteUrl -Name $Site.Name -Description $Site.Description -Template (Get-SPWebTemplate $Site.Template) -AddToQuickLaunch:$true -AddToTopNav:$true -UseParentTopNav:$true -UniquePermissions:$false -Language $Site.Language


    # CUSTOMIZE SUB SITE - LISTS
    $SCLists = $Site.Lists

    #$lib = $SCS.Lists[$Library.Name]
    #$lib.OnQuickLaunch = $true;
    #$lib.Update();

    foreach($Library in $SCLists.List) {    

        $NewSubSite.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
        $NewSubSite.Update();

        $lib = $NewSubSite.Lists[$Library.Name]
        $lib.OnQuickLaunch = $true;
        $lib.Update();

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
    $SCLibraries = $Site.Libraries

    foreach($Library in $SCLibraries.Library) {    
        $NewSubSite.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
        $NewSubSite.Update();

        $lib = $NewSubSite.Lists[$Library.Name]
        $lib.OnQuickLaunch = $true;
        $lib.ContentTypesEnabled = $true
        #$lib.Update();

        $DocSet = $SCS.ContentTypes["Document Set"]
        $ct = $lib.ContentTypes.Add($DocSet)
        $lib.Update();

        # CUSTOMIZE LIBRARY
        foreach($Field in $Library.CustomFields.Field) {
        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");
            
            # Not working - Column found but list doesn't get reference
            if($LookupListName.StartsWith("SC.")) {
                #$LN = $LookupListName.Replace("SC.", "")
                $LookupList = $SCS.Lists[$LookupListName.Replace("SC.", "")]
            } else { 
                $LookupList = $NewSubSite.Lists[$LookupListName.Replace("SC.", "")]
            }            
            
            $LookupListId = "{" +$LookupList.ID + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }
            $regionCol = $Field.OuterXml
            $lib.Fields.AddFieldAsXml($regionCol, $true, [Microsoft.SharePoint.SPAddFieldOptions]::AddFieldToDefaultView)
            $lib.Update();
        }

        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            # Upload File
            $spItem = $null
        
            foreach($ItemField in $ItemData.Field) {
                if($ItemField.GetAttribute("Property").ToLower() -eq "file") {

                    # Assumes local file
                    $LibFile = $ItemField.InnerText
                    $File = Get-ChildItem $LibFile
                    $LibFileName = $LibFile.Substring($LibFile.LastIndexOf("\")+1) 
                
                    $LibFolder = $NewSubSite.GetFolder($Library.Name);

                    $LibFiles = $LibFolder.Files

                    $spItem = $LibFiles.Add($Library.Name+"/"+$LibFileName, $File.OpenRead(),$false)
                    break
                }
            }

            foreach($ItemField in $ItemData.Field) {
                if($ItemField.GetAttribute("Property").ToLower() -ne "file") {

                    $spItem.Item[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
                }
            }

            $spItem.Item.Update()
        }

    }

}
#ENDREGION Create Sites
