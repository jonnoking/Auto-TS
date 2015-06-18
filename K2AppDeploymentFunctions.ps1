# From Ruben
Function RegisterServiceType([string]$k2ConnectionString, [string]$k2Server, [string] $AssemblyP) {
    # Get Paths for local environment and for the remote machine, we might run this installer from a simple windows 7 host, while we deploy to a server that has a different drive...
    $k2Path = "C:\Program Files (x86)\K2 blackpearl\"
    $remK2Path = "C:\Program Files (x86)\K2 blackpearl\"

    $smoManServiceAssembly = Join-Path $k2Path "bin\SourceCode.SmartObjects.Services.Management.dll"
    $serviceBrokerAssembly = Join-Path $remK2Path "ServiceBroker\K2Field.custom.servicebroker.dll"
    
    $guid = [guid]"b12806f6-585d-aaaa-8fff-5710f97f039c" # Guid is hard-coded, no need to have this configurable.

    Write-Debug "Adding/Updating ServiceType $serviceBrokerAssembly with guid $guid using $k2ConnectionString"
    
    Add-Type -Path $smoManServiceAssembly # we load this assembly locally, but we connect to the remote host.
    $smoManService = New-Object SourceCode.SmartObjects.Services.Management.ServiceManagementServer

    #Create connection and capture output (methods return a bool)
    $tmpOut = $smoManService.CreateConnection()
    $tmpOut = $smoManService.Connection.Open($k2ConnectionString);
    Write-Debug "Connected to K2 host server"

    # Check if we need to update or register a new one...
    if ([string]::IsNullOrEmpty($smoManService.GetServiceType($guid)) ) {
        Write-Debug "Registering new service type..."
        $tmpOut = $smoManService.RegisterServiceType($guid, " K2Field.custom.servicebroker", "Custom", "Custom Service Broker", $serviceBrokerAssembly, " K2Field.custom.servicebroker");
        write-debug "Registered new service type..."
    } else {
        Write-Debug "Updating service type..."
        $tmpOut = $smoManService.UpdateServiceType($guid, " K2Field.custom.servicebroker", "Custom", "Custom Service Broker", $serviceBrokerAssembly, " K2Field.custom.servicebroker ");
        Write-Debug "Updated service type..."
    }
    $smoManService.Connection.Close();
    write-host "Deployed service-type"
}

function RefreshInstance()
{


        ##  Refresh ServiceInstance
        #  Load SourceCode.SmartObjects.Services.Management assembly
        Add-Type -Path ($k2InstallDir + "Bin\SourceCode.HostClientAPI.dll")
        Add-Type -Path ($k2InstallDir + "Bin\SourceCode.SmartObjects.Services.Management.dll")

        #  Create connection string
        $connBuilder = New-Object SourceCode.Hosting.Client.BaseAPI.SCConnectionStringBuilder
        $connBuilder.Host = $hostname
        $connBuilder.Port = "5555"
        $connBuilder.Integrated = "true"
        $connBuilder.IsPrimaryLogin = "true"

        $managementServiceInstanceGuid = New-Object Guid("5d273ad6-e27a-46f8-be67-198b36085f99")

        #  Create ServiceManagementServer API
        $managementServer = New-Object SourceCode.SmartObjects.Services.Management.ServiceManagementServer
        $managementServer.CreateConnection()

        Try
        {
            $managementServer.Connection.Open($connBuilder.ConnectionString)
    
            # RefreshServiceInstance
            $managementServer.RefreshServiceInstance($managementServiceInstanceGuid)
        }
        Finally
        {
          $managementServer.Connection.Dispose()
        }

}


function New-K2ServiceType {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ServiceTypeSystemName,
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ServiceTypeDisplayName,
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ServiceTypeDescription,
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ServiceTypeAssemblyPath,
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ServiceTypeClass,
        [Parameter(Mandatory=$false,Position=0)]
        [string]$ServiceTypeGuid
    )

    process {
        $SmoManagementService = Get-K2SmoManagementServer -K2ConnectionString $K2ConnectionString

        if ($ServiceTypeGuid -eq $null) {
            $NewServiceTypeGuid = ([System.Guid]::NewGuid())
        } else {
            $NewServiceTypeGuid = $ServiceTypeGuid
        }

        Write-Host -ForegroundColor Yellow "STARTING: Registering service type" $ServiceTypeDisplayName

        $tmpOut = $SmoManagementService.RegisterServiceType($NewServiceTypeGuid, $ServiceTypeSystemName, $ServiceTypeDisplayName, $ServiceTypeDescription, $ServiceTypeAssemblyPath, $ServiceTypeClass);

        Write-Host -ForegroundColor Green "FINISHED: Registering service type" $ServiceTypeDisplayName
    
        $SmoManagementService.Connection.Close();
    }

}



function Get-K2SmoManagementServer {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString
    )

    process {
        Add-Type -Path ("C:\Program Files (x86)\K2 blackpearl\Bin\SourceCode.SmartObjects.Services.Management.dll")
        $SmoManagementService = New-Object SourceCode.SmartObjects.Services.Management.ServiceManagementServer

        #Create connection and capture output (methods return a bool)
        $tmpOut = $SmoManagementService.CreateConnection()
        $tmpOut = $SmoManagementService.Connection.Open($K2ConnectionString);

        Write-Output $SmoManagementService

    }
}

function Set-K2CopyDeploy {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        $CopyConfig
    )

    process {

        $CopyName = $CopyConfig.GetAttribute("Name")

        Write-Host -ForegroundColor Yellow "STARTING: Copying files for" $CopyName

        # need to validate source and destination are valid directories & add error handling

        $CopySource = $ScriptPath+$CopyConfig.Source
        
        Copy-Item $CopySource $CopyConfig.Destination
        
        Write-Host -ForegroundColor Yellow "FINISHED: Copying files for" $CopyName

    }
}


function Set-K2ExecuteScriptDeploy {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        $CmdletConfig
    )

    process {

        $CmdletName = $CmdletConfig.GetAttribute("Name")

        Write-Host -ForegroundColor Yellow "STARTING: Execution of PowerShell Cmdlet" $CmdletName

        # need to validate if PS1 or batch file and change execution accordingly

        $CmdletFile = $ScriptPath+$CmdletConfig.'#text'

        Write-Host -ForegroundColor Green $CmdletFile

        &($CmdletFile)

        Write-Host -ForegroundColor Yellow "FINISHED: Execution of PowerShell Cmdlet" $CmdletName

    }
}
