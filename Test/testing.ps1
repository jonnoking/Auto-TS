
# Disable Execution Policy
Set-ExecutionPolicy Unrestricted



Specify tenant admin and site URL
$User = "jonno@k2loud.onmicrosoft.com"
$SiteURL = "https://k2loud.sharepoint.com/sites/jonno2/finance"
$Folder = "C:\Development"
$DocLibName = "Products"

#Add references to SharePoint client assemblies and authenticate to Office 365 site - required for CSOM
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
$Password = Read-Host -Prompt "Please enter your password" -AsSecureString

#Bind to site collection
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($User,$Password)
$Context.Credentials = $Creds



    $DocSet = $Context.Web.ContentTypes.GetById("0x0120D520")
    $Context.Load($DocSet)
    $Context.ExecuteQuery()


            
            $LookupListName = "Draft Quotes";

            $LookupList =$Context.Web.Lists.GetByTitle($LookupListName)
            $Context.Load($LookupList)
            $Context.ExecuteQuery()

        $LookupList.ContentTypes.AddExistingContentType($DocSet)
        $Context.ExecuteQuery()






# Load SP Snapin
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue


#$SCS = Get-SPWeb -Identity "https://portal.denallix.com/"

#$L = $SCS.Lists["Customer Tickets"].SchemaXml

#Write-Output($L)

#[Microsoft.SharePoint.SPListTemplateType]::