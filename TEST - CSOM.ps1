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

#GET USER

    $OutputUserObject = $Context.Web.EnsureUser("jonno@k2loud.onmicrosoft.com")
    $Context.Load($OutputUserObject)
    $Context.ExecuteQuery()
    Write-Host $OutputUserObject.Id

    #return 



# GET WEB - WORKS
$EmployeeSite = $Context.Site.OpenWeb("Employee")
$Context.Load($EmployeeSite)
$Context.ExecuteQuery()

Write-Host -ForegroundColor Green $EmployeeSite.Url


# GET LIST - WORKS
$SupportList = $EmployeeSite.Lists.GetByTitle("Support Engineers")
$Context.Load($SupportList)
$Context.ExecuteQuery()

Write-Host -ForegroundColor Green $SupportList.Id



$SupportListData = $config.SelectSingleNode("/Environment/SiteCollection/Sites/Site[3]/Lists/List[1]/ListData")

$List = $SupportList

Write-Host -ForegroundColor Red $SupportListData.OuterXml


    $ListData = $SupportListData
        foreach($ItemData in $ListData.Item) {
            
            $listvalues = @{}

                foreach($ItemField in $ItemData.Field) {
                    $FieldValue = $ItemField.InnerText                

                    $FieldType = $ItemField.GetAttribute("Type")
            
                    if($FieldType -ne $null -and $FieldType -ne "" -and $FieldType.ToLower() -eq "user") {
                
                        #Assumes you've put in a valid email
                        $OutputUserObject = $Context.Web.EnsureUser($FieldValue) #user@tenant.onmicrosoft.com
                        $Context.Load($OutputUserObject)
                        $Context.ExecuteQuery()
                        Write-Host "User Id: "  $OutputUserObject.Id
                        $FieldValue = $OutputUserObject.Id

                        #$FieldValue = 9
                    }

                   $listvalues.Add($ItemField.GetAttribute("Property").Replace(" ", "_x0020_"), $FieldValue)

                }                

                Write-Output $listvalues

            $ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
            $Item = $List.AddItem($ListItemInfo)


            $listvalues.GetEnumerator() | % {
                $Item[$_.Key] = $_.Value
            }

                        $Item.Update()
            $Context.ExecuteQuery()

        }

