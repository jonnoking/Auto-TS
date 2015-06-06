# Load Config
[xml]$config = Get-Content C:\Development\Auto-TS\EnvironmentConfig.xml
$SCLibraries = $config.SelectSingleNode("/Environment/SiteCollection/Libraries")

foreach($Library in $SCLibraries.Library) {    
    Write-Host $Library.Name
    Write-Host $Library.Description
    Write-Host $Library.ListType
    Write-Host


        foreach($Field in $Library.CustomFields.Field) {
            Write-Host $Field.OuterXml
        }
}
