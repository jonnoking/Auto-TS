function Get-K2BlackPearlDirectory {
	$installDirectory = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\SourceCode\BlackPearl\BlackPearl Host Server\").InstallDir 
    	
	if($installDirectory.EndsWith("\") -eq $false) {
		$installDirectory = "$installDirectory\"
	}
    
	$installDirectory
}

function Test-K2Service() {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[string]$server
		)

	$servicePrior = Get-K2Service -server $server
	Write-Verbose "...$($servicePrior.state)"
  $servicePrior.state
}

function Get-K2Service() {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[string]$server
		)		
	(Get-WmiObject -ComputerName $server -Class Win32_Service -Filter "Name='K2 blackpearl Server'")
}

function Restart-K2Server() {
<#
  .Synopsis
		This function restarts the K2 server and wait until it is responding before returning control
  .Description
		This function restarts the K2 server and wait until it is responding before returning control.    
  .Example
		Restart-K2Server "localhost"
  .Example
		Restart-K2Server "dlx" $true 30
  .Parameter $server
		Defaults to localhost
	.Parameter $waitForRestart
		Should the script wait until the K2 service reports it is running again.
  .Parameter $restartDelaySeconds
		How long do you want to wait before attempting to restart the K2 server. Defaults to 0.
  .Notes
		AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(
		[string]$server="localhost",
		[bool]$waitForRestart=$true,
		[int]$restartDelaySeconds=0
		)
	
	# Stop the local / remote K2 Server service			
	$service = Get-K2Service -server $server
				
	Write-Host "Stopping K2 Server on $server"
	$service.StopService() | Out-Null
	
	Write-Verbose "...Waiting for Service Stop on $server"
	while((Test-K2Service -server $server) -ne'Stopped')
	{		
		sleep 2
	}
	
	# Let other stuff do stuff before restarting on this box
	if($restartDelaySeconds -ne 0)
	{
		Write-Verbose "...Pausing for $restartDelaySeconds seconds"
		sleep $restartDelaySeconds
	}
	
	Write-Verbose "...Starting Service on $server"
	$service.StartService() | out-null
	
	if($waitForRestart)
	{
		Write-Verbose "...Waiting for restart"
		while((Test-K2Service -server $server) -ne'Running')
		{		
			sleep 5
		}	
		Write-Host "K2 Server on $server is up and running"
	}
}

function Get-K2ConnectionString {
<#
	.Synopsis
		This function returns a connection string to connect to K2
  .Description
		This function returns a connection string to connect to K2    
  .Example
		Get-K2ConnectionString "localhost"
  .Example
		Get-K2ConnectionString "dlx" $true
	.Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Notes
		AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(		
		[ValidateNotNullOrEmpty()]
		[string]$server="localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port=5555
	)
	BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.HostClientAPI") | Out-Null
	}
	PROCESS
	{
		$conn = New-Object SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder 
		$conn.IsPrimaryLogin = $true
		$conn.Integrated = $true
		$conn.Host = $server
		$conn.Port = $port
		$conn
	}
}

function Close-K2Connection {
	[CmdletBinding()]
	Param(
		$object	
	)
	if(($object -ne $null) -And ($object.Connection -ne $null))
	{
		$object.Connection.Close()			
	}
}

function Get-K2WorkflowManagementServer {
<#
	.Synopsis
		Returns a Workflow management server connection
  .Description
		This function returns a Workflow management server connection
  .Example
		Get-K2WorkflowManagementServer "localhost"
  .Example
		Get-K2WorkflowManagementServer "dlx" 5555 $true
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Parameter $open
		Should the connection be opened? Defaults to true
  .Notes
		AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(	
		[Parameter(Mandatory=$true)]	
		[ValidateNotNullOrEmpty()]
		[string]$server="localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port=5555,		
		[bool]$open=$true
	)	
	BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.Workflow.Management") | Out-Null		
	}
	PROCESS
	{
		$managementServer = New-Object SourceCode.Workflow.Management.WorkflowManagementServer	
		
		if($open)
		{
			$conn = Get-K2ConnectionString -server $server -port $port
			try {
				Write-Verbose "Opening connection to $server on $port"
				$managementServer.CreateConnection() | Out-Null
				$managementServer.Connection.Open($conn) | Out-Null
				Write-Verbose "Connection open"
			}
			catch {
				throw "Unable to connect to $server on $port"
			}
		}
		$managementServer
	}			
}

function Get-K2ServiceManagementServer {
<#
  .Synopsis
		Returns a Service management server connection
  .Description
		This function returns a Service management server connection
  .Example
		Get-K2ServiceManagementServer "localhost"
  .Example
		Get-K2ServiceManagementServer "dlx" 5555 $true
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Parameter $open
		Should the connection be opened? Defaults to true
  .Notes
    AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(	
		[Parameter(Mandatory=$true)]	
		[ValidateNotNullOrEmpty()]
		[string]$server="localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port=5555,		
		[bool]$open=$true
	)	
	BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.SmartObjects.Services.Management") | Out-Null		
	}
	PROCESS
	{
		$serviceManagementServer = New-Object SourceCode.SmartObjects.Services.Management.ServiceManagementServer
		
		if($open)
		{
			$conn = Get-K2ConnectionString -server $server -port $port
			try {
				Write-Verbose "Opening connection to $server on $port"
				$serviceManagementServer.CreateConnection() | Out-Null
				$serviceManagementServer.Connection.Open($conn) | Out-Null
				Write-Verbose "Connection open"
			}
			catch {
				throw "Unable to connect to $server on $port"
			}
		}
		$serviceManagementServer
	}			
}

function Get-K2CategoryServer {
<#
  .Synopsis
		Returns a Category server connection
  .Description
		This function returns a Category server connection
  .Example
		Get-K2CategoryServer "localhost"
  .Example
		Get-K2CategoryServer "dlx" 5555 $true
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Parameter $open
		Should the connection be opened? Defaults to true
  .Notes
    AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(	
		[Parameter(Mandatory=$true)]	
		[ValidateNotNullOrEmpty()]
		[string]$server="localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port=5555,		
		[bool] $open=$true
	)
	BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.Categories.Client.CategoryServer") | Out-Null		
	}
	PROCESS
	{		
		$categoryServer = New-Object SourceCode.Categories.Client.CategoryServer
			
		if($open)
		{
			$conn = Get-K2ConnectionString -server $server -port $port
			try {
				Write-Verbose "Opening connection to $server on $port"
				$categoryServer.CreateConnection() | Out-Null
				$categoryServer.Connection.Open($conn) | Out-Null
				Write-Verbose "Connection open"
			}
			catch {
				Throw "Unable to connect to $server on $port"
			}
		}
		$categoryServer
	}	
}

function Get-K2SmartObjectServer {
<#
  .Synopsis
		Returns a Smart object server connection
  .Description
		This function returns a Smart object server connection
  .Example
		Get-K2SmartObjectServer "localhost"
  .Example
		Get-K2SmartObjectServer "dlx" 5555 $true
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Parameter $open
		Should the connection be opened? Defaults to true
  .Notes
    AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(	
		[Parameter(Mandatory=$true)]	
		[ValidateNotNullOrEmpty()]
		[string]$server="localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port=5555,		
		[bool]$open=$true
	)	
	BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.SmartObjects.Management") | Out-Null		
	}
	PROCESS
	{
		$smartObjectServer = New-Object SourceCode.SmartObjects.Management.SmartObjectManagementServer
		
		if($open)
		{
			$conn = Get-K2ConnectionString -server $server -port $port
			try {
				Write-Verbose "Opening connection to $server on $port"
				$smartObjectServer.CreateConnection() | Out-Null
				$smartObjectServer.Connection.Open($conn) | Out-Null
				Write-Verbose "Connection open"
			}
			catch {
				throw "Unable to connect to $server on $port"
			}
		}
		$smartObjectServer
	}			
}

function Get-K2CategoryManager {
<#
  .Synopsis
		Returns a Category management server connection
  .Description
		This function returns a Category management server connection
  .Example
		Get-K2CategoryManager "localhost"
  .Example
		Get-K2CategoryManager "dlx" 5555 $true
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Parameter $open
		Should the connection be opened? Defaults to true
  .Notes
    AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(		
		[Parameter(ValueFromPipeline=$true, Mandatory=$true)]
		[SourceCode.Categories.Client.CategoryServer]	
		$catServer)
	try 
	{
		$catManager = $categoryServer.GetCategoryManager(1, $true)
	}
  catch
	{
		Throw "Unable to get category manager"
  }

	return $catManager
}

function Get-K2FormsManager {
<#
  .Synopsis
		Returns a Forms management server connection
  .Description
		This function returns a Forms management server connection
  .Example
		Get-K2FormsManager "localhost"
  .Example
		Get-K2FormsManager "dlx" 5555 $true
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
	.Parameter $open
		Should the connection be opened? Defaults to true
  .Notes
    AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$server = "localhost",
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[int]$port=5555,		
		[bool]$open=$true
	)
	BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.Forms.Management") | Out-Null
	}
	PROCESS
	{		
		$formsManager = New-Object SourceCode.Forms.Management.FormsManager
	
		if($open)
		{
			$conn = Get-K2ConnectionString -server $server -port $port
			try {
				Write-Verbose "Opening connection to $server on $port"
				$formsManager.Open($conn) | Out-Null
				Write-Debug "Connection open"
			}
			catch {
				Throw "Unable to connect to $server on $port"
			}
		}
	$formsManager
	}
}

function Get-K2Categories {
<#
  .Synopsis
		Enumerates all K2 categories on the K2 server
  .Description
		Enumerates all K2 categories on the K2 server
  .Example
		Get-K2Categories "localhost"
  .Example
		Get-K2Categories "dlx" 5555 $true
	.Parameter $category
		The category to traverse. Defaults to the root category
  .Parameter $server
		The K2 server to connect to. Defaults to localhost
	.Parameter $port
		The port to use. Defaults to 5555
  .Notes
    AUTHOR: Paul Kelly, K2
		#Requires -Version 2.0
#>
	[CmdletBinding()]
	Param(
		[SourceCode.Categories.Client.Category] $category,
		[ValidateNotNullOrEmpty()]
		[string]$server="localhost",
		[ValidateNotNullOrEmpty()]
		[int]$port=5555
	)
	BEGIN
	{	
		if($category -eq $null) {
			$categoryServer = Get-K2CategoryServer -server $server -port $port		
			$rootCategory = ($categoryServer | Get-K2CategoryManager).RootCategory			
		}
	}
	PROCESS
	{
		if($category -eq $null) {
			$category = $rootCategory
		}
		
		$category.GetChildCategories() | ForEach-Object {		
				Get-K2Categories $_ -server $server -port $port				
				return $_
		}
	}
	END 
	{
		Close-K2Connection $categoryServer
	}
}