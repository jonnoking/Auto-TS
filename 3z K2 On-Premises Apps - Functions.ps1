function RefreshManagementInstance()
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
