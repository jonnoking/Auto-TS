# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfig.xml
$SCLibraries = $config.SelectSingleNode("/Environment/SiteCollection/Lists")

foreach($Library in $SCLibraries.List) {    
    Write-Host $Library.Name
    Write-Host $Library.Description
    Write-Host $Library.ListType
    
    $a = [Microsoft.SharePoint.SPListTemplateType]$Library.ListType

Write-Host


        foreach($Field in $Library.CustomFields.Field) {
            Write-Host $Field.OuterXml
        }
}
