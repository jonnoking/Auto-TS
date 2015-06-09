# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
#Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# Paths to SDK. Please verify location on your computer.    
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"     
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

# Import Modules
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking




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
Connect-SPOService -Url https://k2loud-admin.sharepoint.com/ -Credential $AdminCreds


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

    Remove-SPOSite $SCUrl -Confirm:$false
    Remove-SPODeletedSite -Identity $SCUrl -Confirm:$false
    Write-Host -ForegroundColor Red "Site Collection deleted"

    return 

} else {
   Write-Host -ForegroundColor Red "Site Collection doesn't exist"
}


# CREATE SITE COLLECTION
# THIS HAS A HABIT OF FAILING. IF IT FAILS THE REST OF THE SCIRPT RUNS BUT NOTHING WORKS. NEEDS BETTER EXCEPTION HANDLING (EVERYWHERE)
try {

    New-SPOSite -Url $SCUrl -Title $SCName -Owner $TenantAdmin -Template $SCTemplate -StorageQuota $SCQuota

} catch {

    Write-Host -ForegroundColor Red "Site Collection failed to create. Stopping"
    return
    
}

# get site collection
$SC = Get-SPOSite $SCUrl -Detailed


# Add Everyone to Members group
$SCGroupMembers = $SCName + " Members"
Add-SPOUser -Site $SC -Group $SCGroupMembers -LoginName "C:0(.s|true"

Disconnect-SPOService

Write-Host -ForegroundColor Green "Site Collection Created"


$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SCUrl)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($TenantAdmin, $TenantAdminPwdSecure)
$Context.Credentials = $Creds


# CUSTOMIZE PARENT SITE - LISTS
$SCLists = $config.SelectNodes("/Environment/SiteCollection/Lists")

foreach($Library in $SCLists.List) {    

    $ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
    $ListInfo.Title = $Library.Name
    $ListInfo.TemplateType = [Microsoft.SharePoint.SPListTemplateType]$Library.ListType #$ListDictionary.Get_Item($Library.ListType)
    $List = $Context.Web.Lists.Add($ListInfo)
    $List.Description = $Library.Description

    $ListQuickLaunch = $null
    $ListQuickLaunch = $Library.GetAttribute("QuickLaunch")
    if ($ListQuickLaunch -ne $null -and $ListQuickLaunch.ToLower() -ne "false") {
        $List.OnQuickLaunch = $true
    }       

    $List.Update()
    $Context.ExecuteQuery()



    foreach($Field in $Library.CustomFields.Field) {

        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");

            $LookupList =$Context.Web.Lists.GetByTitle($LookupListName)
            $Context.Load($LookupList)
            $Context.ExecuteQuery()

            $LookupListId = "{" +$LookupList.Id + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }

        $regionCol = $Field.OuterXml
        $List.Fields.AddFieldAsXml($regionCol ,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
        $List.Update()
        $Context.ExecuteQuery()

    }


    # Add List Data    
    $ListData = $Library.ListData
    foreach($ItemData in $ListData.Item) {

        $ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
        $Item = $List.AddItem($ListItemInfo)
        
        foreach($ItemField in $ItemData.Field) {
            $Item[$ItemField.GetAttribute("Property").Replace(" ", "_x0020_")] = $ItemField.InnerText
        }

        $Item.Update()
        $Context.ExecuteQuery()

    }
}


# CUSTOMIZE PARENT SITE - LIBRARIES
$SCLibraries = $config.SelectNodes("/Environment/SiteCollection/Libraries")

foreach($Library in $SCLibraries.Library) {    

    $ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
    $ListInfo.Title = $Library.Name
    $ListInfo.TemplateType = [Microsoft.SharePoint.SPListTemplateType]$Library.ListType #$ListDictionary.Get_Item($Library.ListType)
    $List = $Context.Web.Lists.Add($ListInfo)
    $List.Description = $Library.Description
    $List.ContentTypesEnabled = $true
    
    $ListQuickLaunch = $null
    $ListQuickLaunch = $Library.GetAttribute("QuickLaunch")
    if ($ListQuickLaunch -ne $null -and $ListQuickLaunch.ToLower() -ne "false") {
        $List.OnQuickLaunch = $true
    }       

    $List.Update()
    $Context.ExecuteQuery()

    # Get Document Set Content Type
    $DocSet = $Context.Web.ContentTypes.GetById("0x0120D520")
    $Context.Load($DocSet)
    $Context.ExecuteQuery()

    # Add Document Set Content Type To Library
    $cts = $List.ContentTypes
    $Context.Load($cts)
    $ctReturn = $cts.AddExistingContentType($DocSet)
    $Context.Load($ctReturn)
    $Context.ExecuteQuery()

           

    foreach($Field in $Library.CustomFields.Field) {

        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupListName = $Field.GetAttribute("List");

            $LookupList =$Context.Web.Lists.GetByTitle($LookupListName)
            $Context.Load($LookupList)
            $Context.ExecuteQuery()

            $LookupListId = "{" +$LookupList.Id + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }

        $regionCol = $Field.OuterXml
        $List.Fields.AddFieldAsXml($regionCol ,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
        $List.Update()
        $Context.ExecuteQuery()

    }


    # Add List Data    
    $ListData = $Library.ListData
    foreach($ItemData in $ListData.Item) {

    # Upload File
    # Needs to allow for uploading to Document Sets - Check it exists, create if required, upload to Doc Set
        $Upload = $null
        
        foreach($ItemField in $ItemData.Field) {
            if($ItemField.GetAttribute("Property").ToLower() -eq "file") {



                # Assumes local file
                $LibFile = $ItemField.InnerText
                $File = Get-ChildItem $LibFile
                $LibFileName = $LibFile.Substring($LibFile.LastIndexOf("\")+1) 
                
                $FileStream = New-Object IO.FileStream($File, [System.IO.FileMode]::Open)
                $FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
                $FileCreationInfo.Overwrite = $true
                $FileCreationInfo.ContentStream = $FileStream
                $FileCreationInfo.URL = $LibFile.Substring($LibFile.LastIndexOf("\")+1)                 




                $Folder = $ItemData.GetAttribute("Folder")

                $Fldr = $null
                $DSL = $null
                if ($Folder -ne $null -and $Folder -ne "") {
                    
                    # Check if DocSet exists

                    try {
                        $DSL = $Context.Web.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
                        $Context.Load($DSL)
                        $Context.ExecuteQuery()


                    } catch {
                        # Doc Set not found

                        $DocSet = $Context.Web.ContentTypes.GetById("0x0120D520")
                        $Context.Load($DocSet)
                        $Context.ExecuteQuery()

                        $Fldr = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
                        $Fldr.UnderlyingObjectType = 1  # 1 = Folder - FileSystemObjectType enumeration
                        $Fldr.LeafName = $Folder

                        $DSItem = $List.AddItem($Fldr)
                        $DSItem["ContentTypeId"] = $DocSet.Id
                        $DSItem["Title"] = $Folder
                        $DSItem.Update()
                        $Context.Load($List)
                        $Context.ExecuteQuery()

                        $DSL = $Context.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
                        $Context.Load($DSL)
                        $Context.ExecuteQuery()

                        
                    }

                    $Upload = $DSL.Files.Add($FileCreationInfo)                    
                  

                } else {

                    $Upload = $List.RootFolder.Files.Add($FileCreationInfo)


                }

                
                $UploadItem = $Upload.ListItemAllFields;

                #$Context.ExecuteQuery()

                foreach($ItemField in $ItemData.Field) {
                    if($ItemField.GetAttribute("Property").ToLower() -ne "file") {

                        $UploadItem[$ItemField.GetAttribute("Property").Replace(" ", "_x0020_")] = $ItemField.InnerText
                    }
                }
                $UploadItem.Update()
                $Context.Load($Upload)
                $Context.ExecuteQuery()
                


                $FileStream.Dispose()

                break;
            }
        }                
    }

}
    # MODIFY THE SITE LOGO
    #Get the short file name of the first item in the document library "Assets"
    $LongFileName = $config.SelectSingleNode("/Environment/SiteCollection/Libraries/Library[Name='Assets']/ListData/Item[1]/Field[@Property='File']").InnerText
    $FileName = $LongFileName.Substring($LongFileName.LastIndexOf("\")+1) 
    $Context.Web.SiteLogoUrl = "/sites/" + $SCUrlName + "/Assets/" + $FileName
    $Context.Web.Update();
    $Context.ExecuteQuery();


    # REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING ALL TOP LEVEL SITE ASSETS
    $QLNav = $Context.Web.Navigation.QuickLaunch; 
    $Context.Load($QLNav)
    $Context.ExecuteQuery()

    $QLRecent = $null
    $QLNav | where {$_.Title -eq 'Recent'} |  foreach {
        $QLRecent = $_
    }

    $QLNoebook = $null
    $QLNav | where {$_.Title -eq 'Notebook'} |  foreach {
        $QLNoebook = $_
    }
    
    $QLDocs = $null
    $QLNav | where {$_.Title -eq 'Documents'}|  foreach {
        $QLDocs = $_
    }
    
    if ($QLRecent -ne $null) { $QLRecent.DeleteObject() }
    if ($QLNoebook -ne $null) { $QLNoebook.DeleteObject() }
    if ($QLDocs -ne $null) { $QLDocs.DeleteObject() }

    $Context.ExecuteQuery()




# CUSTOMIZE SITE - SITES
$SCSites = $config.SelectNodes("/Environment/SiteCollection/Sites")

foreach($Site in $SCSites.Site) {

    $SiteUrl = $SCUrl + "/" + $Site.UrlName
    #Remove-SPWeb -Identity $SiteUrl -Confirm:$false


    $WCI = New-Object Microsoft.SharePoint.Client.WebCreationInformation
    $WCI.Title = $Site.Name
    $WCI.WebTemplate = $Site.Template
    $WCI.Description = $Site.Description
    $WCI.Url = $Site.UrlName
    $WCI.Language = $Site.Language
    $NewSubSite = $Context.Web.Webs.Add($WCI)
    $Context.ExecuteQuery()

    $NewSubSite.Navigation.UseShared = $true    
    $Context.Load($NewSubSite)
    $Context.ExecuteQuery()

    
    # Add Quick Launch Navigation - top navigation menu
    $collQuickLaunchNode = $Context.Web.Navigation.TopNavigationBar;
    $ciNavicationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
    $ciNavicationNode.Title = $Site.Name
    $ciNavicationNode.Url = $Site.UrlName
    $ciNavicationNode.AsLastNode = $true
    $QLN = $collQuickLaunchNode.Add($ciNavicationNode)
    $Context.Load($collQuickLaunchNode)
    $Context.ExecuteQuery()


    
    # CUSTOMIZE SUB SITE - LISTS
    $SCLists = $Site.Lists
    foreach($Library in $SCLists.List) {    

        $ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
        $ListInfo.Title = $Library.Name
        $ListInfo.TemplateType = [Microsoft.SharePoint.SPListTemplateType]$Library.ListType 
        $List = $NewSubSite.Lists.Add($ListInfo)
        $List.Description = $Library.Description

        $ListQuickLaunch = $null
        $ListQuickLaunch = $Library.GetAttribute("QuickLaunch")
        if ($ListQuickLaunch -ne $null -and $ListQuickLaunch.ToLower() -ne "false") {
            $List.OnQuickLaunch = $true
        }       

        $List.Update()
        $Context.ExecuteQuery()

        foreach($Field in $Library.CustomFields.Field) {

            if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
                $LookupListName = $Field.GetAttribute("List");

                $LookupList =$Context.Web.Lists.GetByTitle($LookupListName)
                $NewSubSite.Load($LookupList)
                $Context.ExecuteQuery()

                $LookupListId = "{" +$LookupList.Id + "}"
                $Field.SetAttribute("List", $LookupListId) 
            }

            $regionCol = $Field.OuterXml
            $List.Fields.AddFieldAsXml($regionCol ,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
            $List.Update()
            $Context.ExecuteQuery()

        }


        # Add List Data    
        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            $ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
            $Item = $List.AddItem($ListItemInfo)
        
            foreach($ItemField in $ItemData.Field) {
                $Item[$ItemField.GetAttribute("Property").Replace(" ", "_x0020_")] = $ItemField.InnerText
            }

            $Item.Update()
            $Context.ExecuteQuery()

        }


    }


    # CUSTOMIZE SUB SITE - LIBRARIES
    $SCLibraries = $Site.Libraries
    foreach($Library in $SCLibraries.Library) {    

        $ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
        $ListInfo.Title = $Library.Name
        $ListInfo.TemplateType = [Microsoft.SharePoint.SPListTemplateType]$Library.ListType #$ListDictionary.Get_Item($Library.ListType)
        $List = $NewSubSite.Lists.Add($ListInfo)
        $List.Description = $Library.Description
        $List.ContentTypesEnabled = $true

        $ListQuickLaunch = $null
        $ListQuickLaunch = $Library.GetAttribute("QuickLaunch")
        if ($ListQuickLaunch -ne $null -and $ListQuickLaunch.ToLower() -ne "false") {
            $List.OnQuickLaunch = $true
        }
               
        $List.Update()
        $Context.ExecuteQuery()



        # Get Document Set Content Type
        $DocSet = $Context.Web.ContentTypes.GetById("0x0120D520")
        $Context.Load($DocSet)
        $Context.ExecuteQuery()

        # Add Document Set Content Type To Library
        $cts = $List.ContentTypes
        $Context.Load($cts)
        $ctReturn = $cts.AddExistingContentType($DocSet)
        $Context.Load($ctReturn)
        $Context.ExecuteQuery()
           

    foreach($Field in $Library.CustomFields.Field) {

        
        if($Field.GetAttribute("Type").ToLower() -eq "lookup") {
            
            $LookupList = $null
            $LookupListName = $Field.GetAttribute("List");

            if($LookupListName.StartsWith("SC.")) {
                $LookupList =$Context.Web.Lists.GetByTitle($LookupListName.Replace("SC.", ""))
            } else { 
                $LookupList =$NewSubSite.Lists.GetByTitle($LookupListName.Replace("SC.", ""))
            }            

            $Context.Load($LookupList)
            $Context.ExecuteQuery()

            $LookupListId = "{" +$LookupList.Id + "}"
            $Field.SetAttribute("List", $LookupListId) 
        }

        $regionCol = $Field.OuterXml
        $List.Fields.AddFieldAsXml($regionCol ,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
        $List.Update()
        $Context.ExecuteQuery()

    }


    # Add List Data    
    $ListData = $Library.ListData
    foreach($ItemData in $ListData.Item) {

    # Upload File
    # Needs to allow for uploading to Document Sets - Check it exists, create if required, upload to Doc Set
        $Upload = $null
        
        foreach($ItemField in $ItemData.Field) {
            if($ItemField.GetAttribute("Property").ToLower() -eq "file") {

                # Assumes local file
                $LibFile = $ItemField.InnerText
                $File = Get-ChildItem $LibFile
                $LibFileName = $LibFile.Substring($LibFile.LastIndexOf("\")+1) 
                
                $FileStream = New-Object IO.FileStream($File, [System.IO.FileMode]::Open)
                $FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
                $FileCreationInfo.Overwrite = $true
                $FileCreationInfo.ContentStream = $FileStream
                $FileCreationInfo.URL = $LibFile.Substring($LibFile.LastIndexOf("\")+1)                 
                
                #$Upload = $List.RootFolder.Files.Add($FileCreationInfo)

                $Folder = $ItemData.GetAttribute("Folder")

                $Fldr = $null
                $DSL = $null
                if ($Folder -ne $null -and $Folder -ne "") {
                    
                    # Check if DocSet exists

                    try {
                        $DSL = $Context.Web.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
                        $Context.Load($DSL)
                        $Context.ExecuteQuery()


                    } catch {
                        # Doc Set not found

                        $DocSet = $Context.Web.ContentTypes.GetById("0x0120D520")
                        $Context.Load($DocSet)
                        $Context.ExecuteQuery()

                        $Fldr = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
                        $Fldr.UnderlyingObjectType = 1  # 1 = Folder - FileSystemObjectType enumeration
                        $Fldr.LeafName = $Folder

                        $DSItem = $List.AddItem($Fldr)
                        $DSItem["ContentTypeId"] = $DocSet.Id
                        $DSItem["Title"] = $Folder
                        $DSItem.Update()
                        $Context.Load($List)
                        $Context.ExecuteQuery()

                        $DSL = $Context.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
                        $Context.Load($DSL)
                        $Context.ExecuteQuery()

                        
                    }

                    $Upload = $DSL.Files.Add($FileCreationInfo)      
                    
                  

                } else {

                    $Upload = $List.RootFolder.Files.Add($FileCreationInfo)


                }
                
                $UploadItem = $Upload.ListItemAllFields;

                #$Context.ExecuteQuery()

                foreach($ItemField in $ItemData.Field) {
                    if($ItemField.GetAttribute("Property").ToLower() -ne "file") {

                        $UploadItem[$ItemField.GetAttribute("Property").Replace(" ", "_x0020_")] = $ItemField.InnerText
                    }
                }
                $UploadItem.Update()
                $Context.Load($Upload)
                $Context.ExecuteQuery()

                $FileStream.Dispose()

                break;
            }
        }                
    }


}

    # REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING ALL SUBSITE ASSETS
    $QLNav = $NewSubSite.Navigation.QuickLaunch; 
    $Context.Load($QLNav)
    $Context.ExecuteQuery()

    $QLRecent = $null
    $QLNav | where {$_.Title -eq 'Recent'} |  foreach {
        $QLRecent = $_
    }

    $QLNoebook = $null
    $QLNav | where {$_.Title -eq 'Notebook'} |  foreach {
        $QLNoebook = $_
    }
    
    $QLDocs = $null
    $QLNav | where {$_.Title -eq 'Documents'}|  foreach {
        $QLDocs = $_
    }
    
    if ($QLRecent -ne $null) { $QLRecent.DeleteObject() }
    if ($QLNoebook -ne $null) { $QLNoebook.DeleteObject() }
    if ($QLDocs -ne $null) { $QLDocs.DeleteObject() }

    $Context.ExecuteQuery()


    # Reorganize Quick Launch

    # Update Pages

}


$Context.Dispose()



