#REUSABLE FUNCTIONS
#Note that there may be differences between the Online versions of these functions

function Set-K2SPSiteLogo {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$LongFileName,
        [Parameter(Mandatory=$true,Position=1)]
        $SPWeb,
        [Parameter(Mandatory=$true,Position=2)]
        $SCUrlName
    )

    process {

        # MODIFY THE SITE LOGO
        $FileName = $LongFileName.Substring($LongFileName.LastIndexOf("\")+1) 
        $SPWeb.SiteLogoUrl = "/sites/" + $SCUrlName + "/SiteAssets/" + $FileName
        $SPWeb.Update();
    }

}

function Get-K2UserID
{
  
   param (
        [Parameter(Mandatory=$true,Position=0)]
		[string]$UserName,
        [Parameter(Mandatory=$true,Position=1)]
        $SPWeb
		)

        try {
            $SPUser = $SPWeb.EnsureUser($UserName)
            $UserID= $SPUser.ID.ToString()+";#"+$SPUser.DisplayName
            Write-Output $UserID
        } catch {
            
            Write-Output $null
        
        }


}

function Set-K2TrimMenu
{
    param (
    [Parameter(Mandatory=$true,Position=0)]
    $SPWeb
    )
    
    $QLNav = $SPWeb.Navigation.QuickLaunch


    $QLRecent = $null
    $QLNav | where {$_.Title -eq 'Recent'} |  foreach {
        $QLRecent = $_
    }

    $QLNotebook = $null
    $QLNav | where {$_.Title -eq 'Notebook'} |  foreach {
        $QLNotebook = $_
    }
    
    $QLDocs = $null
    $QLNav | where {$_.Title -eq 'Documents'}|  foreach {
        $QLDocs = $_
    }
    
    if ($QLRecent -ne $null) { $QLNav.Delete($QLRecent)}
    if ($QLNotebook -ne $null) { $QLNav.Delete($QLNotebook)}
    if ($QLDocs -ne $null) { $QLNav.Delete($QLDocs)}

    $SPWeb.Update()

}

function Get-K2SPList {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$ListName
    )

    process {

        try {            
            $LookupList = $SPWeb.Lists[$ListName]
            Write-Output $LookupList
        } catch {
            return $null
        }
    }
}

function Add-K2DataToList {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$Library,
        [Parameter(Mandatory=$true,Position=2)]
		$List
    )

    process {
        try {
        $ListData = $Library.ListData
        foreach($ItemData in $ListData.Item) {

            $spItem = $List.AddItem()

            foreach($ItemField in $ItemData.Field) {
                   $FieldType = $ItemField.GetAttribute("Type")
                   if($FieldType -ne $null -and $FieldType -ne "" -and $FieldType.ToLower() -eq "user") {
                      $spItem[$ItemField.GetAttribute("Property")] = Get-K2UserID -UserName $ItemField.InnerText -SPWeb $SPweb 
                  }
                  else
                 {
                     $spItem[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
                  }
         }
            $spItem.Update()
        }

        }
        catch {
            Write-Host -ForegroundColor Blue "Error adding data to list " $Library.Name
        }
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

            Write-Host -ForegroundColor Blue "Creating List " $Library.Name
            $SPWeb.Lists.Add($Library.Name, $Library.Description, [Microsoft.SharePoint.SPListTemplateType]$Library.ListType);
            $SPWeb.Update();

            $lib = $SPWeb.Lists[$Library.Name]
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
            

        } catch {
            Write-Host -ForegroundColor DarkRed "Error creating list " $Library.Name
            return $null
        }

    }
}

function New-K2EnableDocumentType {

    param(
        [Parameter(Mandatory=$true,Position=0)]
		$SPWeb,
        [Parameter(Mandatory=$true,Position=1)]
		$List
    )

    process {

        # Get Document Set Content Type
        $DocSet = $SPWeb.ContentTypes["Document Set"]
        
        # Add Document Set Content Type To Library
        $List.ContentTypes.Add($DocSet)
        $List.Update()
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

                $DSL = $SPWeb.GetFolder($List.RootFolder.ServerRelativeUrl + "/" + $Folder)
                if (-not $DSL.Exists)
                {
                    # Doc Set not found
                    $cType = $List.ContentTypes["Document Set"]
                    $DSL = [Microsoft.Office.DocumentManagement.DocumentSets.DocumentSet]::Create($List.RootFolder,$Folder,$cType.Id, $docsetProperties)
        
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
                #$Upload = $DSL.Files.Add($FileCreationInfo.Url, $FileStream, $true)
                $Upload = $DSL.Folder.Files.Add($FileCreationInfo.Url, $FileStream, $true)
                $Upload.Update()
            } else { 
                $Upload = $List.RootFolder.Files.Add($FileCreationInfo.Url, $FileStream, $true)
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

            $ListValuesHash.GetEnumerator() | % {
                $UploadItem[$_.Key] = $_.Value
            }

            $UploadItem.Update()


            $FileStream.Dispose()
        }

        #Write-Output $List
    }

}