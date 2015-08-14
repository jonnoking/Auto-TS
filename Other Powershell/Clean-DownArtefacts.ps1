. .\Common-K2Functions

function Delete-AllProcesses
{
 [CmdletBinding()]
	Param([string]$server,
		  [int]$port)
	BEGIN
	{
		$workflowManagementServer =	Get-K2WorkflowManagementServer -server $server -port $port
	}
	PROCESS
	{
		$workflowManagementServer.GetProcSets() | ForEach-Object {		
			Write-Verbose "Deleting process $($_.FullName)"
			$workflowManagementServer.DeleteProcessDefinition($_.FullName, 0, $true) | Out-Null
		}
	}
	END
	{
		Close-K2Connection $workflowManagementServer
	}
}

function Delete-AllSmartObjects
{
	[CmdletBinding()]
	Param([string]$server,
		  [int]$port)
	BEGIN
	{
		$smartObjectServer = Get-K2SmartObjectServer -server $server -port $port
	}
	PROCESS
	{
		$soExplorer = $smartObjectServer.GetSmartObjects([SourceCode.SmartObjects.Management.SmartObjectInfoType]::User)
		 $soExplorer.SmartObjectList | ForEach-Object {
			Write-Verbose "Deleting Smartobject $_.Name"
			# Need to trap this as the SmartObjects returned can be system ones, even though the specified SmO type was set to User
			trap
			{
				
				$soServer.DeleteSmartObject($smo.Guid, $true)
				continue
			}	
    }
	}
	END
	{
		Close-K2Connection $smartObjectServer
	}
}

#Delete-AllProcesses -server 'localhost' -port 5555 -verbose
#Delete-AllSmartObjects  -server 'localhost' -port 5555 -verbose