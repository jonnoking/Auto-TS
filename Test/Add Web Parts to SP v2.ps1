Remove-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue
Add-PSSnapin Microsoft.SharePoint.Powershell
 
function AddWebPartToPage([string]$siteUrl,[string]$pageRelativeUrl,[string]$localWebpartPath,[string]$ZoneName,[int]$ZoneIndex)
{
 
    try
    {
 
    #this reference is required here
    $clientContext= [Microsoft.SharePoint.Client.ClientContext,Microsoft.SharePoint.Client, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]
    $context=New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
    write-host "Reading file " $pageRelativeUrl
    $oFile = $context.Web.GetFileByServerRelativeUrl($pageRelativeUrl);
    $limitedWebPartManager = $oFile.GetLimitedWebPartManager([Microsoft.Sharepoint.Client.WebParts.PersonalizationScope]::Shared);
    write-host "getting xml reader from file"
    $xtr = New-Object System.Xml.XmlTextReader($localWebpartPath)
     [void] [Reflection.Assembly]::LoadWithPartialName("System.Text")
    $sb = new-object System.Text.StringBuilder
 
         while ($xtr.Read())
         {
            $tmpObj = $sb.AppendLine($xtr.ReadOuterXml());
         }
         $newXml =  $sb.ToString()
 
    if ($xtr -ne $null)
    {
        $xtr.Close()
    }
 
    #Add Web Part to catalogs folder
    write-host "Adding Webpart....."
    $oWebPartDefinition = $limitedWebPartManager.ImportWebPart($newXml);
    $limitedWebPartManager.AddWebPart($oWebPartDefinition.WebPart, $ZoneName, $ZoneIndex);
    $context.ExecuteQuery();
    write-host "Adding Web Part Done"
    }
    catch
    {
    write-host "Error while 'AddWebPartToPage'" $_.exception
    }
 
}
 
#Checks out the page
function CheckOutPage ($SPFile)
{
    $x=$SPFile.ServerRelativeUrl
    if($SPFile.Level -eq [Microsoft.SharePoint.SPFileLevel]::Checkout)
    {
        write-host " File already checked-out...doing undo checkout"
 
        $SPFile.UndoCheckOut()
    }
 
    if ($SPFile.Level -ne [Microsoft.SharePoint.SPFileLevel]::Checkout)
    {
        write-host " Checking-out page" $x
 
        $SPFile.CheckOut()
    }
    else
    {
        write-host " No Check-out needed page" $x
 
    }
} 
 
#check in the page
function CheckInPage ($SPFile)
{
    $x=$SPFile.ServerRelativeUrl
    write-host "file level" $SPFile.Level -ForegroundColor Green
    if ($SPFile.Level -eq [Microsoft.SharePoint.SPFileLevel]::Checkout)
    {
        write-host " Checking-in page" $x
 
        $SPFile.CheckIn("Checkin", [Microsoft.SharePoint.SPCheckInType]::MajorCheckin)
    }
    else
    {
        write-host " No Check-in needed page" $x
 
    }
 
} 
 
#Approve the page
function ApprovePage ($PageListItem)
{
    if($PageListItem.ListItems.List.EnableModeration)
    {
        #Check to ensure page requires approval, and if so, approve it
        try{
            write-host " Approving page" $PageListItem.File.ServerRelativeUrl
 
            $PageListItem.File.Publish("")
            $PageListItem.File.Approve("Page approved automatically by PowerShell script")
        }
        catch
        {
            write-host $_
 
        }
    }
    else
    {
        write-host " No approval on list"
 
    }
}
 
#Add Web Part to the page
function AddWebPart($wpTitle, $wpDestinationPageFullUrl, $wpLocalPath, $wpZoneName, $wpZoneIndex, $IsReplace)
{
 
[Microsoft.SharePoint.SPFile] $spFile = $Web.GetFile($wpDestinationPageFullUrl)
if($spFile.Exists)
    {
        try
        {
        if ($SPFile.CheckOutStatus -ne "None")
        {
         write-host "doing undocheckout"
         $SPFile.UndoCheckOut()
        }
        else
        {
            write-host "checkout the page" -ForeGround Green
            CheckOutPage -SPFile $spFile
        }
 
        ####
        [Microsoft.SharePoint.WebPartPages.SPLimitedWebPartManager]$wpManager = $Web.GetLimitedWebPartManager($FullUrl,[System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared) 
 
        if ($null -eq [System.Web.HttpContext]::Current)
        {
            $sw = New-Object System.IO.StringWriter
            $resp = New-Object System.Web.HttpResponse $sw
            $req = New-Object System.Web.HttpRequest "", $Web.Url, ""
            $htc = New-Object System.Web.HttpContext $req, $resp
            #explicitly cast $web to spweb object else sharepoint will
            #see it as a PSObject, and AddWebpart wil fail
            $htc.Items["HttpHandlerSPWeb"] = $web  -as [Microsoft.SharePoint.SPweb]
            [System.Web.HttpContext]::Current = $htc
            if ($sw -ne $null)
            {
                $sw.Dispose()
            }
        }
        $Web.AllowUnsafeUpdates = $true
 
        if ($IsReplace -eq $true)
        {
 
            $wpToDelete = $wpManager.WebParts | % { $_ }
            foreach($WebPart in $wpToDelete)
            {
                if($WebPart -ne $null)
                {
                    if($WebPart.Title -eq $WebPartTitle)
                    {
                    write-host "deleting existing Web Part" $WebPart.Title -ForegroundColor Green
                    $wpManager.DeleteWebPart($WebPart)
                    }
 
                }
            }
        }
        ####
 
        $pageRelativeUrl = $SPFile.ServerRelativeUrl
        AddWebPartToPage $siteUrl $pageRelativeUrl $wpLocalPath $wpZoneName $wpZoneIndex
        }
        catch
        {
            write-host $_.exception
        }
        finally
        {
            #check in
            CheckInPage -SPFile $spFile
 
            # Approve & Publish
            ApprovePage -PageListItem $spFile.Item
 
            if($wpManager -ne $null)
            {
                $wpManager.Dispose()
            }
            if($Web -ne $null)
            {
                    $Web.AllowUnsafeUpdates = $false
                    $Web.Dispose()
            }
        }
 
    }
}
 
## Main Programm ##
try
{
    $runningDir = resolve-Path .\
    $configXmlPath = join-path -path $runningDir -childpath "WebPartToPageConfig.xml"
    [xml]$SiteConfig = get-content $configXmlPath
    $siteUrl = $SiteConfig.Config.SiteSettings.Url
    $Web = Get-SPWeb -identity $siteUrl
 
    foreach($WebPart in $SiteConfig.Config.WebParts.WebPart)
    {
        #if attributes are present to the node, use innerText as $WebPart.Title will not return value
        #$wpTitle = $WebPart.Title.InnerText
        $wpTitle = $WebPart.Title
        $FullUrl = $WebPart.DestinationPagePath
        $LocalWebPartPath = $WebPart.LocalSrc
        $ZoneName = $WebPart.ZoneName
        $ZoneIndex = $WebPart.ZoneIndex
        $Replace = $WebPart.Replace
 
        AddWebPart $wpTitle $FullUrl $LocalWebPartPath $ZoneName $ZoneIndex $Replace
 
    }
}
catch
{
write-host $error[0]
}
finally
{
    if($Web -ne $null)
    {
        $Web.Dispose()
    }
 
}
 
Pop-Location