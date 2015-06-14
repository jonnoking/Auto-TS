# RESUABLE FUNCTIONS


function Get-K2EnsureUser
{
  
   param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$UserNameEmail
		)

        try {

            $OutputUserObject = $Context.Web.EnsureUser($UserNameEmail) #user@tenant.onmicrosoft.com
            $Context.Load($OutputUserObject)
            $Context.ExecuteQuery()
            
            Write-Output $OutputUserObject

        } catch {
            
            Write-Output $null
        
        }


}


function New-K2SPList {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$Library
    )

    process {

        try {

            $ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
            $ListInfo.Title = $Library.Name
            $ListInfo.TemplateType = [Microsoft.SharePoint.SPListTemplateType]$Library.ListType #$ListDictionary.Get_Item($Library.ListType)
            $List = $SPWeb.Lists.Add($ListInfo)
            $List.Description = $Library.Description
            $List.ContentTypesEnabled = $true
        
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

                    $LookupList = Get-K2SPList -SPWeb $SPWeb -ListName $Library.Name
                    if($LookupList -ne $null) {
                        $LookupListId = "{" +$LookupList.Id + "}"
                        $Field.SetAttribute("List", $LookupListId) 
                    }
                }

                $regionCol = $Field.OuterXml
                $List.Fields.AddFieldAsXml($regionCol ,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
                $List.Update()
                $Context.ExecuteQuery()
                
            }

            #Write-Output $List

        } catch {
            return $null
        }

    }

}

function Delete-K2SPList {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$ListTitle
    )


    process {

        $list = $SPWeb.Lists.GetByTitle($ListTitle)
        $list.DeleteObject()
        $Context.ExecuteQuery()
    }
}


function Enable-K2SharePointFeature {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$FeatureGuid
    )


    process {

        $guiFeatureGuid = [System.Guid]$FeatureGuid
        $SPWeb.Features.Add($guiFeatureGuid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None) 
        $Context.ExecuteQuery() 
    }
}

function Disable-K2SharePointFeature {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$FeatureGuid
    )


    process {

        $guiFeatureGuid = [System.Guid]$FeatureGuid
        $SPWeb.Features.Remove($guiFeatureGuid, $true) 
        $Context.ExecuteQuery() 
    }
}


function Add-K2DataToList {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$Library,
        [Parameter(Mandatory=$true,Position=2)]
		$List
    )

    process {

        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            $ListValuesHash = @{}

            # Populate values into hash - avoids reseting $Item issue
            foreach($ItemField in $ItemData.Field) {
            
                $FieldValue = $ItemField.InnerText

                $FieldType = $ItemField.GetAttribute("Type")
            
                if($FieldType -ne $null -and $FieldType -ne "" -and $FieldType.ToLower() -eq "user") {
                
                    $OutputUserObject = Get-K2EnsureUser -UserNameEmail $FieldValue                
                    $FieldValue = $OutputUserObject.Id
                }

                $ListValuesHash.Add($ItemField.GetAttribute("Property").Replace(" ", "_x0020_"), $FieldValue)            
            }

            # Create new item
            $ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
            $Item = $List.AddItem($ListItemInfo)

            $ListValuesHash
            $ListValuesHash.GetEnumerator() | % {
                $Item[$_.Key] = $_.Value
            }

            $Item.Update()
            $Context.ExecuteQuery()

        }

        #Write-Output $List

    }

}


function Add-K2DocumentsToLibrary {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$Library,
        [Parameter(Mandatory=$true,Position=2)]
		$List
    )

    process {

            # Add List Data    
        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            # Upload File
            $Upload = $null
        
            $ItemFieldFile = $ItemData.SelectSingleNode("Field[@Property='File']")

            $Folder = $ItemData.GetAttribute("Folder")

            $Fldr = $null
            $DSL = $null
            if ($Folder -ne $null -and $Folder -ne "") {
                    
                # Check if DocSet exists

                try {
                    $DSL = $SPWeb.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
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

                    $DSL = $SPWeb.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
                    $Context.Load($DSL)
                    $Context.ExecuteQuery()

                        
                }
            }

            # Assumes local file
            $LibFile = $ItemFieldFile.InnerText
            $File = Get-ChildItem $LibFile
            $LibFileName = $LibFile.Substring($LibFile.LastIndexOf("\")+1) 
                
            $FileStream = New-Object IO.FileStream($File, [System.IO.FileMode]::Open)
            $FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
            $FileCreationInfo.Overwrite = $true
            $FileCreationInfo.ContentStream = $FileStream
            $FileCreationInfo.URL = $LibFile.Substring($LibFile.LastIndexOf("\")+1) 


            if ($Folder -ne $null -and $Folder -ne "") {
                $Upload = $DSL.Files.Add($FileCreationInfo)                    
            } else { 
                $Upload = $List.RootFolder.Files.Add($FileCreationInfo)
            }

            $UploadItem = $Upload.ListItemAllFields;



            $ListValuesHash = @{}

            # Populate values into hash - avoids reseting $Item issue
            foreach($ItemField in $ItemData.Field) {
                if($ItemField.GetAttribute("Property").ToLower() -ne "file") {
                    $FieldValue = $ItemField.InnerText

                    $FieldType = $ItemField.GetAttribute("Type")
            
                    if($FieldType -ne $null -and $FieldType -ne "" -and $FieldType.ToLower() -eq "user") {
                
                        #Assumes you've put in a valid email
                        $OutputUserObject = Get-K2EnsureUser -UserNameEmail $FieldValue
                        $FieldValue = $OutputUserObject.Id
                    }

                    $ListValuesHash.Add($ItemField.GetAttribute("Property").Replace(" ", "_x0020_"), $FieldValue)            
                }
            }
            
            $ListValuesHash
            $ListValuesHash.GetEnumerator() | % {
                $UploadItem[$_.Key] = $_.Value
            }

            $UploadItem.Update()
            $Context.Load($Upload)
            $Context.ExecuteQuery()

            $FileStream.Dispose()
        }

        #Write-Output $List
    }

}


function New-K2EnableDocumentType {

    param(
        [Parameter(Mandatory=$true,Position=1)]
		$List
    )

    process {

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

        #Write-Output $List

    }

}

function Get-K2SPList {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,

        [Parameter(Mandatory=$true,Position=1)]
        [string]$ListName
    )

    process {
        try
        {           
            $LookupList =$SPWeb.Lists.GetByTitle($ListName)
            $Context.Load($LookupList)
            $Context.ExecuteQuery()
            Write-Output $LookupList
        } catch {
            return $null
        }
    }
}


function Set-K2SPSiteLogo {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$LongFileName
    )

    process {

        # MODIFY THE SITE LOGO
        #Get the short file name of the first item in the existing document library "Site Assets"
        #$LongFileName = $config.SelectSingleNode("/Environment/SiteCollection/Existing/Libraries/Library[Name='Site Assets']/ListData/Item[1]/Field[@Property='File']").InnerText
        $FileName = $LongFileName.Substring($LongFileName.LastIndexOf("\")+1) 
        $Context.Web.SiteLogoUrl = "/sites/" + $SCUrlName + "/SiteAssets/" + $FileName
        $Context.Web.Update();
        $Context.ExecuteQuery();
    }

}


function Set-K2TrimMenu {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb
    )

    process {

        # REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING ALL TOP LEVEL SITE ASSETS
        $QLNav = $SPWeb.Navigation.QuickLaunch; 
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
    }

}


function Set-K2TrimMenuItem {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$MenuItem
    )

    process {

        # REMOVE UNNCESSARY QUICK LAUNCH NAVIGATION - DO AFTER ADDING ALL TOP LEVEL SITE ASSETS
        $QLNav = $SPWeb.Navigation.QuickLaunch; 
        $Context.Load($QLNav)
        $Context.ExecuteQuery()

        $QLMeunItem = $null
        $QLNav | where {$_.Title -eq $MenuItem} |  foreach {
            $QLMeunItem = $_
        }

        if ($QLMeunItem -ne $null -and $QLMeunItem -ne "") {
            $QLMeunItem.DeleteObject() 
            $Context.ExecuteQuery()
        }

    }
}

function New-K2CreateSite {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$Site

    )

    process {

            $SiteUrl = $SCUrl + "/" + $Site.UrlName
            #Remove-SPWeb -Identity $SiteUrl -Confirm:$false


            $WCI = New-Object Microsoft.SharePoint.Client.WebCreationInformation
            $WCI.Title = $Site.Name
            $WCI.WebTemplate = $Site.Template
            $WCI.Description = $Site.Description
            $WCI.Url = $Site.UrlName
            $WCI.Language = $Site.Language
            $NewSubSite = $SPWeb.Webs.Add($WCI)
            $Context.ExecuteQuery()

            $NewSubSite.Navigation.UseShared = $true    
            $Context.Load($NewSubSite)
            $Context.ExecuteQuery()

    
            # Add Quick Launch Navigation - top navigation menu
            $collQuickLaunchNode = $SPWeb.Navigation.TopNavigationBar;
            $ciNavicationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
            $ciNavicationNode.Title = $Site.Name
            $ciNavicationNode.Url = $Site.UrlName
            $ciNavicationNode.AsLastNode = $true
            $QLN = $collQuickLaunchNode.Add($ciNavicationNode)
            $Context.Load($collQuickLaunchNode)
            $Context.ExecuteQuery()

            #Write-Output $NewSubSite
    }

}


function Set-K2WebHomePage {
    [CmdletBinding()]


    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$PageUrl
    )

    process {
        
        $rootFolder = $SPWeb.RootFolder; 
        $rootFolder.WelcomePage = $PageUrl;
        $rootFolder.Update();
        $Context.ExecuteQuery();
   }
}


function Get-K2SPWeb {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,

        [Parameter(Mandatory=$true,Position=1)]
        [string]$SiteName
    )

    process {
        try
        {
            #Needs improving

            #$rootWeb = $SPWeb.Web
            $childWebs = $SPWeb.Webs
            #$Context.Load($rootWeb)
            $Context.Load($childWebs)
            $Context.ExecuteQuery()          

            foreach($child in $childWebs) {
            Write-Host $child.Title $child.Description
                if ($child.Title -eq $SiteName) {
                    Write-Output $child
                    break
                }

            }
                        
        } catch {
            return $null
        }
    }
}


function Add-K2SideLoadApp {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$AppPath
    )

    process {

        $appIoStream = New-Object IO.FileStream($AppPath ,[System.IO.FileMode]::Open)
        $appInstance = $SPWeb.LoadAndInstallApp($appIoStream) | Out-Null
        $Context.ExecuteQuery()

        $appIoStream.Dispose()
    }

}