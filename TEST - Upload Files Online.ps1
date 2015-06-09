# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
#Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue

# Paths to SDK. Please verify location on your computer.    
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"     
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

# Import Modules
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
#Import-Module SPOMod


# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfigOnline.xml
    $LongFileName = $config.SelectSingleNode("/Environment/SiteCollection/Existing/Libraries/Library[Name='Site Assets']/ListData/Item[1]/Field[@Property='File']").InnerText
Write-Host -ForegroundColor Green $LongFileName
break

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

} else {
   Write-Host -ForegroundColor Red "Site Collection doesn't exist"
    return 
}

Disconnect-SPOService

$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SCUrl)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($TenantAdmin, $TenantAdminPwdSecure)
$Context.Credentials = $Creds


# GET WEB - WORKS
$FinanceSite = $Context.Site.OpenWeb("Finance")
$Context.Load($FinanceSite)
$Context.ExecuteQuery()

Write-Host -ForegroundColor Green $FinanceSite.Url


# GET LIST - WORKS
$QuotesList = $FinanceSite.Lists.GetByTitle("Site Assets")
$Context.Load($QuotesList)
$Context.ExecuteQuery()

$l = 0

#return

$LKJ = $FinanceSite.GetFolderByServerRelativeUrl("Approved Quotes/JJK")
$Context.Load($LKJ)
$Context.ExecuteQuery()

Write-Host -for Green $LKJ.Name




#$QuotesListData = $config.SelectSingleNode("/Environment/SiteCollection/Sites/Site[1]/Libraries/Library[2]/ListData")
$QuotesListData = $config.SelectSingleNode("/Environment/SiteCollection/Existing/Libraries/Library[1]/ListData")
$List = $QuotesList

Write-Host -ForegroundColor Red $QuotesListData.OuterXml

    # Add List Data    
    $ListData = $QuotesListData
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
                        $DSL = $FinanceSite.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
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

                        $DSL = $FinanceSite.GetFolderByServerRelativeUrl($List.Title+"/"+$Folder)
                        $Context.Load($DSL)
                        $Context.ExecuteQuery()

                        
                    }

                    $Upload = $DSL.Files.Add($FileCreationInfo)

                    Write-Host -ForegroundColor Cyan $DSL.Name

                } else {

                    $Upload = $List.RootFolder.Files.Add($FileCreationInfo)
                    #$List.AddItem($FileCreationInfo, "$Folder",  [Microsoft.SharePoint.SPFileSystemObjectType]::File, $null)


                }

                
                $UploadItem = $Upload.ListItemAllFields;

                Write-Host -ForegroundColor Cyan $UploadItem.DisplayName

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

return














    # Add List Data    
    $ListData = $QuotesListData
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
                $Upload = $Fldr.Files.Add($FileCreationInfo)

                
                $UploadItem = $Upload.ListItemAllFields;

                #$Context.ExecuteQuery()

                foreach($ItemField in $ItemData.Field) {
                    if($ItemField.GetAttribute("Property").ToLower() -ne "file") {

                        $UploadItem[$ItemField.GetAttribute("Property")] = $ItemField.InnerText
                        #.Replace(" ", "_x0020_")
                    }
                }
                $UploadItem.Update()
                $Context.Load($Upload)
                $Context.ExecuteQuery()
                break;
            }
        }                
    }


    # Remove Quick Launch Navigation - left hand side menu

    $QLNav = $FinanceSite.Navigation.QuickLaunch;    
    $Context.Load($QLNav)
    $Context.ExecuteQuery()

    $QLNav | foreach {
        Write-Host $_.Title + " - " + $_.Url
    }


    #$QLRecent = $null
    $QLNav | where {$_.Title -eq 'Recent'} |  foreach {
        $QLRecent = $_
    }

    Write-Output $QLRecent.Title

    $QLRecent.DeletedObject()
    $Context.ExecuteQuery()

    return

    $QLNoebook = $null
    $QLNav | where {$_.Title -eq 'Notebook'} |  foreach {
        $QLNoebook = $_
    }
    
    $QLDocs = $null
    $QLNav | where {$_.Title -eq 'Documents'}|  foreach {
        $QLDocs = $_
    }
    
    
    $QLRecent.DeletedObject()
    $QLNoebook.DeleteObject()
    $QLDocs.DeleteObject()

    $Context.ExecuteQuery()
    $stop =1

return


    $QLNav | where {$_.Title -eq 'Recent'} |  foreach {
        $Node = $_.DeleteObject()
    }
    $Context.ExecuteQuery()

    $QLNav = $FinanceSite.Navigation.QuickLaunch;    
    $Context.Load($QLNav)
    $Context.ExecuteQuery()
        
    $QLNav | where {$_.Title -eq 'Notebook'} |  foreach {
        $Node = $_.DeleteObject()
    }
    $Context.ExecuteQuery()


    $QLNav = $FinanceSite.Navigation.QuickLaunch;    
    $Context.Load($QLNav)
    $Context.ExecuteQuery()
    $QLNav | where { $_.Title -eq 'Documents'} |  foreach {
        $Node = $_.DeleteObject()
    }

    $Context.ExecuteQuery()
        

    return


# Add Top Navigation - top navigation menu
    $collQuickLaunchNode = $Context.Web.Navigation.TopNavigationBar;
    $ciNavicationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
    $ciNavicationNode.Title = "Jonno Finance"
    $ciNavicationNode.Url = "finance"
    $ciNavicationNode.AsLastNode = $true
    $QLN = $collQuickLaunchNode.Add($ciNavicationNode)
    $Context.Load($collQuickLaunchNode)
    $Context.ExecuteQuery()

    return



# Add Quick Launch Navigation - left hand side menu

    $collQuickLaunchNode = $Context.Web.Navigation.QuickLaunch;
    $ciNavicationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
    $ciNavicationNode.Title = "Site Name"
    $ciNavicationNode.Url = "finance"
    $ciNavicationNode.AsLastNode = $true
    $QLN = $collQuickLaunchNode.Add($ciNavicationNode)
    $Context.Load($collQuickLaunchNode)
    $Context.ExecuteQuery()

    return


        # Add Document Set Content Type
    $cts = $QuotesList.ContentTypes
    $Context.Load($cts)
    $ctReturn = $cts.AddExistingContentType($DocSet)
    $Context.Load($ctReturn)
    $Context.ExecuteQuery()
return
Write-Host -ForegroundColor Green $QuotesList.Id



$SupportListData = $config.SelectSingleNode("/Environment/SiteCollection/Sites/Site[1]/Lists/List[3]/ListData")

$List = $QuotesList

Write-Host -ForegroundColor Red $SupportListData.OuterXml


    # Add List Data    
    $ListData = $SupportListData
    foreach($ItemData in $ListData.Item) {

        $ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
        $Item = $List.AddItem($ListItemInfo)
        
        foreach($ItemField in $ItemData.Field) {
            $Item[$ItemField.GetAttribute("Property").Replace(" ", "_x0020_")] = $ItemField.InnerText
        }

        $Item.Update()
        $Context.ExecuteQuery()

    }

return
