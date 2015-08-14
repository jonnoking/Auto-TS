. .\Common-K2Functions

function Register-ServiceType {
	[CmdletBinding()]
	Param([string]$server="localhost",
		  [int]$port=5555,
		  [System.Xml.XmlElement]$serviceConfiguration,
		  [string]$dllPath=""
		  )
	BEGIN
	{
		$serviceManagementServer = Get-K2ServiceManagementServer -server $server -port $port	
	}
	PROCESS
	{		
		if($dllPath -eq "") {
			$dllUri = Join-Path (Get-K2BlackPearlDirectory) -ChildPath ServiceBroker | Join-Path -ChildPath $serviceConfiguration.serviceTypeAssemblyName
		}
		else {
			$dllUri =  Join-Path $dllPath -ChildPath $serviceConfiguration.serviceTypeAssemblyName
		}
		
		Write-Host "Service Type $($serviceConfiguration.displayName)"		
		Write-Verbose "Guid $($serviceConfiguration.guid)"
		Write-Verbose "SystemName $($serviceConfiguration.systemName)"
		Write-Verbose "DisplayName $($serviceConfiguration.displayName)"
		Write-Verbose "Description $($serviceConfiguration.description)"			
		Write-Verbose "Path $($dllUri)"
		Write-Verbose "Class $($serviceConfiguration.className)"
		
		$serviceType = $serviceManagementServer.GetServiceType($serviceConfiguration.guid)
		
		if($serviceType -eq $null) {
			$typeConfig = "<servicetype name=""$($serviceConfiguration.systemName)"" guid=""$($serviceConfiguration.guid)"">"
			$typeConfig += "<metadata>"
			$typeConfig += "<display>"			
			$typeConfig += "<displayname>$($serviceConfiguration.displayName)</displayname>"
			$typeConfig += "<description>$($serviceConfiguration.description)</description>"
			$typeConfig += "</display>"
			$typeConfig += "</metadata>"
			$typeConfig += "<config>"
			$typeConfig += "<assembly path=""$dllUri"" class=""$($serviceConfiguration.className)"" />"
			$typeConfig += "</config>"
			$typeConfig += "</servicetype>"
			
			Write-Host "Creating $($serviceConfiguration.displayName)"
			$serviceManagementServer.RegisterServiceType(
				$serviceConfiguration.guid,
				$typeConfig)
			
			Write-Host "Created"							
		}
		else {
			Write-Host "Updating $($serviceConfiguration.displayName)"	
			 $serviceManagementServer.UpdateServiceType(
				$serviceConfiguration.guid,
				$serviceConfiguration.systemName,
				$serviceConfiguration.displayName,
				$serviceConfiguration.description,
				$dllUri,
				$serviceConfiguration.className)
				
			Write-Host "Updated"
		}
	}
	END
	{
		Close-K2Connection $serviceManagementServer
	}	
}

function Register-ServiceInstance {
	[CmdletBinding()]
	Param([string]$server="localhost",
		  [int]$port=5555,
			[string]$environment,
			[guid]$serviceTypeGuid,
		  [System.Xml.XmlElement]$serviceInstanceConfiguration			
		  )
	BEGIN
	{
		$serviceManagementServer = Get-K2ServiceManagementServer -server $server -port $port	
	}
	PROCESS
	{	
		Write-Host "Service Instance $($serviceInstanceConfiguration.displayName)"		
		Write-Verbose "Guid $($serviceInstanceConfiguration.guid)"
		Write-Verbose "SystemName $($serviceInstanceConfiguration.systemName)"
		Write-Verbose "DisplayName $($serviceInstanceConfiguration.displayName)"
		Write-Verbose "Description $($serviceInstanceConfiguration.description)"		
		Write-Verbose "Impersonate $($serviceInstanceConfiguration.impersonate)"
			
		$configValues = ($serviceInstanceConfiguration.Environment | Where-Object { $_.name	-eq $environment }).Config
		
		$instanceConfig = "<serviceconfig>"
		$instanceConfig += "<serviceauthentication impersonate=""$($serviceInstanceConfiguration.impersonate)"" isrequired=""false"">"
		$instanceConfig += "<username />"			
		$instanceConfig += "<password />"
		$instanceConfig += "<extra />"
		$instanceConfig += "</serviceauthentication>"
		$instanceConfig += "<settings>"
		
		Write-Verbose "Config values for $($environment):"
		
		$configValues | ForEach-Object {
				 Write-Verbose "...$($_.name)=$($_.value) required=$($_.required)"
				 
				 $instanceConfig += "<key name=""$($_.name)"" isrequired=""$($_.required)"">$($_.value)</key>"
			}
		
		$instanceConfig += "</settings>"		
		$instanceConfig += "</serviceconfig>"
		
		try {
			$serviceInstance = $serviceManagementServer.GetServiceInstance($serviceInstanceConfiguration.guid)
		}
		catch {	}
		
		if($serviceInstance -eq $null) {							
			Write-Host "Creating $($serviceInstanceConfiguration.displayName)"
			
			$serviceManagementServer.RegisterServiceInstance(
				$serviceTypeGuid,
				$serviceInstanceConfiguration.guid,
				$serviceInstanceConfiguration.systemName,
				$serviceInstanceConfiguration.displayName,
				$serviceInstanceConfiguration.description,
				$instanceConfig) | Out-Null
			
			Write-Host "Created"							
		}
		else {
			Write-Host "Updating $($serviceInstanceConfiguration.displayName)"	
			
			$serviceManagementServer.UpdateServiceInstance(
				$serviceTypeGuid,
				$serviceInstanceConfiguration.guid,
				$serviceInstanceConfiguration.systemName,
				$serviceInstanceConfiguration.displayName,
				$serviceInstanceConfiguration.description,
				$instanceConfig) | Out-Null
			
			Write-Host "Updated"
		}
	}
	END
	{
		Close-K2Connection $serviceManagementServer
	}	
}

CLS

$Environment = "Development"

# Go grab the manifest
$ManifestFile = "K2Manifest.xml"

$serverManifest = [xml](Get-Content $ManifestFile)
$selectedEnvironment = $serverManifest.K2BlackPearlServerManifest.Environments.$Environment
	
$k2server = $selectedEnvironment.K2HostServer
$k2serverPort = $selectedEnvironment.K2HostServerPort

$serviceConfiguration = $serverManifest.K2BlackPearlServerManifest.ServiceTypes.ServiceType

$serviceConfiguration | Where-Object { $_.deploy -eq $true } | ForEach-Object {
	Register-ServiceType -server $k2server -port $k2serverPort -serviceConfiguration $_ -verbose
}

$serviceConfiguration | ForEach-Object {
	Register-ServiceInstance -server $k2server -port $k2serverPort -environment $selectedEnvironment.ToString() -serviceTypeGuid $_.guid -serviceInstanceConfiguration $_.ServiceInstance -verbose
}