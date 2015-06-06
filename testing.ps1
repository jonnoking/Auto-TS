# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

# Load SP Snapin
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue


$SCS = Get-SPWeb -Identity "https://portal.denallix.com/"

$L = $SCS.Lists["Customer Tickets"].SchemaXml

Write-Output($L)

[Microsoft.SharePoint.SPListTemplateType]::