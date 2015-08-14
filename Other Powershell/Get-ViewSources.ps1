. .\Common-K2Functions

[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.Forms.Management") | Out-Null

function Export-K2SmartFormViewDataSources {
	[CmdletBinding()]
	Param(
		[Parameter(ValueFromPipeline=$true)]
		[SourceCode.Categories.Client.Category] $category,
		[string] $currentCategory,
		[string]$server = "localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port = 5555,		
		[Parameter(ValueFromPipeline=$true)]
		[SourceCode.Forms.Management.FormsManager] $formsManager		
	)
	BEGIN
	{		
		$formsManager = Get-K2FormsManager -server $server -port $port
	}
	PROCESS
	{
		$category.DataList | Where-Object { $_.dataType -eq "View" } | ForEach-Object {		
			$item = [xml]$formsManager.GetViewDefinition($_.Name)	
			
			if($item -ne $null)
			{
				$viewName = $_.Name
				$item.selectNodes("/SourceCode.Forms/Views/View/Sources/Source") | ForEach-Object {
					New-Object psobject -Property @{
						ViewName = $viewName
						Id = $_.SourceID
						Name = $_.Name}	
				}
			}	
		}
	}
	END
	{
		Close-K2Connection $formsManager
	}	
}

$server = "localhost"
$port = 5555

Get-K2Categories | Export-K2SmartFormViewDataSources