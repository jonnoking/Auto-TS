. .\Common-K2Functions

function Set-ServerPermissions {
	[CmdletBinding()]
	Param([string]$server,
		  [int]$port,
		  [System.Xml.XmlElement]$permissionSet,
		  [bool]$reset=$true
		  )
	BEGIN
	{
		$managementServer = Get-K2WorkflowManagementServer -server $server -port $port	
	}
	PROCESS
	{
		$adminPermissions = $managementServer.GetAdminPermissions()
		
		$newAdminPermissions = New-Object SourceCode.Workflow.Management.AdminPermissions
		
		$adminPermissions | ForEach-Object {
			$newAdminPermissions.Add($_)
		}
			
		$permissionSet.User | ForEach-Object {
			Write-Verbose "Setting Server Permissions for $($_.user)"
			$adminPermission = New-Object SourceCode.Workflow.Management.AdminPermission				
			$adminPermission.UserName = $_.user
			$adminPermission.Admin = [System.Convert]::ToBoolean($_.admin)
			$adminPermission.CanImpersonate = [System.Convert]::ToBoolean($_.canimpersonate)
			$adminPermission.Export = [System.Convert]::ToBoolean($_.export)		
			$newAdminPermissions.Add($adminPermission)				
		}				
		
		$rightsSet = $managementServer.UpdateAdminUsers($newAdminPermissions) 
		
		if($rightsSet) {
			Write-Host "Server rights set"
		}
	}
	END
	{
		Close-K2Connection $managementServer
	}	
}

function Reset-ProcessPermissions {
	Param([string]$server,
		  [string]$port,
		  [string]$workflow,
		  [System.Xml.XmlElement]$permissionSet,
		  [bool]$reset=$true
		  )	
	BEGIN
	{
		$managementServer = Get-K2WorkflowManagementServer -server $server -port $port		
	}
	PROCESS
	{
		$userPermissions = New-Object SourceCode.Workflow.Management.Permissions
		$groupPermissions = New-Object SourceCode.Workflow.Management.Permissions	
		
		$procUpdated = $false
		
		$managementServer.GetProcSets() | ForEach-Object {
			if($_.FullName -eq $workflow)
			{
				$procSetId = $_.ProcSetID
				$permissionSet.Permission | ForEach-Object {
					
					$procSetPermissions = New-Object SourceCode.Workflow.Management.ProcSetPermissions
					$procSetPermissions.ProcSetID = $procSetId
					$procSetPermissions.Start = [System.Convert]::ToBoolean($_.start)
					$procSetPermissions.View = [System.Convert]::ToBoolean($_.view)
					$procSetPermissions.ViewPart = [System.Convert]::ToBoolean($_.viewparticipate)
					$procSetPermissions.Admin = [System.Convert]::ToBoolean($_.admin)
					
					if($_.type.ToLower() -eq "group")
					{
						$procSetPermissions.GroupName = $_.user
						$groupPermissions.Add($procSetPermissions);
					}
					else
					{
						$procSetPermissions.UserName = $_.user
						$userPermissions.Add($procSetPermissions)
					}
					
					if($reset)
					{
					 if($userPermissions.Count -gt 0)					
					 {						
							$procUpdated = $managementServer.UpdateProcUserPermissions($procSetId, $userPermissions) 
					 }
					
					 if($groupPermissions.Count -gt 0)
					 {
							$managementServer.UpdateProcGroupPermissions($procSetId, $groupPermissions)
						}
					}
					else 
					{
						$procUpdated = $managementServer.UpdateOrAddProcUserPermissions($procSetId, $userPermissions)
						Write-Host "Unable to set only group permissions"
					}
				}
				break
			}
			if($procUpdated) {Write-Host "Process rights set"}
		}		
	}
	END
	{
		Close-K2Connection $managementServer
	}
}

$Environment = "Development"

# Go grab the manifest
$ManifestFile = "K2Manifest.xml"

$serverManifest = [xml](Get-Content $ManifestFile)
$selectedEnvironment = $serverManifest.K2BlackPearlServerManifest.Environments.$Environment
	
$k2server = $selectedEnvironment.K2HostServer
$k2serverPort = $selectedEnvironment.K2HostServerPort

$adminPermsXml = $selectedEnvironment.K2ServerRights.Users

Set-ServerPermissions -server $k2server -port $k2serverPort -permissionSet $adminPermsXml -verbose
		
$serverManifest.K2BlackPearlServerManifest.Workflows.Workflow | ForEach-Object {
		$wfFullName = "{0}\{1}" -f $_.folder, $_.name		
		$permissions = ($_.Environment | Where-Object { $_.name	-eq $selectedEnvironment.ToString() }).Permissions
		
		Reset-ProcessPermissions -server $k2server -port $k2serverPort -workflow $wfFullName -permissionSet $permissions
}