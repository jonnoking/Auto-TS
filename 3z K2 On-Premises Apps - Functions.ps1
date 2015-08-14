function Get-K2BlackPearlDirectory {
	$installDirectory = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\SourceCode\BlackPearl\BlackPearl Host Server\").InstallDir 
    	
	if($installDirectory.EndsWith("\") -eq $false) {
		$installDirectory = "$installDirectory"
	}
    
	Write-Output $installDirectory
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
		Write-Output $conn
	}
}

##### DEPLOY K2 SharePoint Apps

##### Create SharePoint Asset

    # TO DO - CALL EXISTING SHAREPOINT POWERSHELL FUNCTION

#####

function Get-K2SmoClient {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString
    )
    BEGIN
	{
		[System.Reflection.Assembly]::LoadWithPartialName("SourceCode.SmartObjects.Services.Client") | Out-Null		
	}
    process {
        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }
        $RefPath = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.SmartObjects.Client.dll"
        Add-Type -Path  $RefPath
        $SmoClient = New-Object SourceCode.SmartObjects.Client.SmartObjectClientServer

        #Create connection and capture output (methods return a bool)
        $tmpOut = $SmoClient.CreateConnection()
        $tmpOut = $SmoClient.Connection.Open($K2ConnectionString);

        Write-Output $SmoClient

    }
}

function Set-K2SmOSPLoadPackage {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$SiteUrl,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$SiteName,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$ListName,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$ListId,
        [Parameter(Mandatory=$true,Position=4)]
        [string]$PackagePath
    )

    process {

        # Get Package as Base64
        $PackageFilename = [System.IO.Path]::GetFileName($PackagePath)
        $PackageBase64 = Get-Base64Document -FilePath $PackagePath
        $PackageSmartFileXml = Get-K2SmoFileProperty -Name "PackageFile" -DisplayName "Package File" -Filename $PackageFilename -Base64 $PackageBase64

        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods")

        $SPHelperSmo.ListMethods["LoadPackage"].InputProperties["SiteUrl"].Value = $SiteUrl;
        $SPHelperSmo.ListMethods["LoadPackage"].InputProperties["SiteName"].Value = $SiteName;
        $SPHelperSmo.ListMethods["LoadPackage"].InputProperties["ListName"].Value = $ListName;
        $SPHelperSmo.ListMethods["LoadPackage"].InputProperties["ListId"].Value = $ListId;
        ([SourceCode.SmartObjects.Client.SmartFileProperty]$SPHelperSmo.ListMethods["LoadPackage"].InputProperties["packageFile"]).FileName = $PackageFilename
        ([SourceCode.SmartObjects.Client.SmartFileProperty]$SPHelperSmo.ListMethods["LoadPackage"].InputProperties["packageFile"]).Content = $PackageBase64[1];

        $SPHelperSmo.MethodToExecute = "LoadPackage"

        $LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $LoadPackageResultSmo = New-Object SourceCode.SmartObjects.Client.SmartObject


        foreach ($Result in $LoadPackageList)
        {
            $LoadPackageResultSmo = $Result
            break
        }

        $SessionName = $LoadPackageResultSmo.Properties["k2_Int_Result"].Value;

        if ($SessionName -eq "") {
            #FAIL
        }

        Write-Output $SessionName

    }
    END
    {
        $SmoClient.Connection.Close()

    }
}


function Get-K2SmoFileProperty {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$DisplayName,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$Filename,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$Base64
    )

    process {      

        $FP = '<smartfileproperty name="'  + $Name + '" type="File" unique="False" system="False">'
        $FP += '<metadata>'
        $FP += '<display>'
        $FP += '<displayname>' + $DisplayName + '</displayname>'
        $FP += '<description></description>'
        $FP += '</display>'
        $FP += '</metadata>'
        $FP += '<filename>' + $Filename + '</filename>'
        $FP += '<filecontent>' + $Base64 + '</filecontent>'
        $FP += '</smartfileproperty>'

        Write-Output $FP

    }
}


function Get-Base64Document {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$FilePath
    )

    process {      

        


        #$FileStream = [System.IO.File]::OpenRead("C:\K2\SharePoint Apps\K2 Application Accelerator - Leave Request v1.1.kspx")
        #$FB = New-Object Byte[] $FileStream.Length
        #$FileStream.Read($FB, 0, $FileStream.Length)
        #$FileContentEncoded = [System.Convert]::ToBase64String($FB)
        #$FileStream.Close()

        $FileContentEncoded = ""
        $FileStream = [System.IO.File]::OpenRead($FilePath)
        $FB = New-Object Byte[] $FileStream.Length
        $FileStream.Read($FB, 0, $FileStream.Length)
        $FileContentEncoded = [System.Convert]::ToBase64String($FB).ToString()
        


        #$FileContent = get-content $FilePath -encoding byte
        #$FileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($FileContent)
        #$FileContentEncoded = [System.Convert]::ToBase64String($FileContentBytes)

        Write-Output $FileContentEncoded
        #returning as an array of strings for some reason.
    }
    END
    {
        $FileStream.Close()
    }
}


#####


function Get-K2SmoManagementServer {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString
    )

    process {
        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        Add-Type -Path (Get-K2BlackPearlDirectory + "\Bin\SourceCode.SmartObjects.Services.Management.dll")
        $SmoManagementService = New-Object SourceCode.SmartObjects.Services.Management.ServiceManagementServer

        #Create connection and capture output (methods return a bool)
        $tmpOut = $SmoManagementService.CreateConnection()
        $tmpOut = $SmoManagementService.Connection.Open($K2ConnectionString);

        Write-Output $SmoManagementService

    }
}







#####


function RefreshManagementInstance()
{


        ##  Refresh ServiceInstance
        #  Load SourceCode.SmartObjects.Services.Management assembly
        Add-Type -Path (Get-K2BlackPearlDirectory + "\Bin\SourceCode.HostClientAPI.dll")
        Add-Type -Path (Get-K2BlackPearlDirectory + "\Bin\SourceCode.SmartObjects.Services.Management.dll")

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
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString
    )

    process {
        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        Add-Type -Path (Get-K2BlackPearlDirectory + "\Bin\SourceCode.SmartObjects.Services.Management.dll")
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



function Get-K2RoleManagementServer {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString
    )

    process {
        Add-Type -Path (Get-K2BlackPearlDirectory + "\Bin\SourceCode.Security.UserRoleManager.Management.dll")
        $RoleManagementService = New-Object SourceCode.Security.UserRoleManager.Management.UserRoleManager

        #Create connection and capture output (methods return a bool)
        $tmpOut = $RoleManagementService.CreateConnection()
        $tmpOut = $RoleManagementService.Connection.Open($K2ConnectionString);

        Write-Output $RoleManagementService

    }
}

function New-K2Role {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Name,        
        [Parameter(Mandatory=$false,Position=2)]
        [string]$Description,        
        [Parameter(Mandatory=$false,Position=3)]
        [bool]$IsDynamic,        
        [Parameter(Mandatory=$false,Position=4)]
        [int]$RefreshInterval        
    )

    process {

        Write-Host -ForegroundColor Yellow "STARTING: Creating Role " $Name                

        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString

        $K2Role = $null
        
        $K2Role = $RoleManagementService.GetRole($Role)

        if ($K2Role -eq $null) {

            # K2 Role doesn't already exists
            $K2Role = New-Object SourceCode.Security.UserRoleManager.Management.Role

            $K2Role.Name = $Name
            $K2Role.Description = $Description
            $K2Role.IsDynamic = $IsDynamic

            if ($RefreshInterval > 0) {
                $K2Role.Interval = $RefreshInterval
            }

            $RoleManagementService.CreateRole($K2Role)

        } 
#        else 
#        {
#            $K2Role.Description = $Description
#            $K2Role.IsDynamic = $IsDynamic
#            if ($RefreshInterval > 0) {
#                $K2Role.Interval = $RefreshInterval
#            }
#            $RoleManagementService.UpdateRole($K2Role)
#        }

        Write-Host -ForegroundColor Green "FINISHED: Creating Role " $Name
    
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}

function Get-K2RoleExists {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Name,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$RoleMember,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$RoleMemberType,
        [Parameter(Mandatory=$false,Position=4)]
        [string]$IncludeExclude
    )

    process {

        Write-Host -ForegroundColor Green "STARTING: Check if Role Exists " $Name
        
        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString


        $K2Role = $null
        
        $K2Role = $RoleManagementService.GetRole($Role)


        Write-Host -ForegroundColor Green "FINISHED: Check if Role Exists " $Name
    
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null

        if ($K2Role -eq $null) {
            Write-Output $false
        } else {
            Write-Output $true
        }

    }

}


function New-K2RoleMember {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Role,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$RoleMember,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$RoleMemberType,
        [Parameter(Mandatory=$false,Position=4)]
        [string]$IncludeExclude
    )

    process {
        if ($IncludeExclude -eq "") {
            $IncludeExclude = "include"
        }

        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString


        $K2Role = $RoleManagementService.GetRole($Role)

        Write-Host -ForegroundColor Yellow "STARTING: Adding member to role" $K2Role.Name                

        $RoleItem = $null

        switch($RoleMemberType.ToLower())
        {
            "user" 
                {
                    $NewItem = New-Object SourceCode.Security.UserRoleManager.Management.UserItem
                    $NewItem.Name = $RoleMember.ToUpper()
                    $RoleItem = $NewItem
                }
            "group"
                {
                    $NewItem = New-Object SourceCode.Security.UserRoleManager.Management.GroupItem
                    $NewItem.Name = $RoleMember.ToUpper()
                    $RoleItem = $NewItem
                }
        }

        if ($IncludeExclude.ToLower() -eq "include") {
            $K2Role.Include.Add($RoleItem)
        } else {
            $K2Role.Exclude.Add($RoleItem)
        }

        $K2Role.ExpiryDate = [System.DateTime]::Now

        $RoleManagementService.UpdateRole($K2Role)


        Write-Host -ForegroundColor Green "FINISHED: Adding member to role" $Role
    
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}


function Delete-K2RoleMember {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Role,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$RoleMember
    )

    process {

        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString


        $K2Role = $RoleManagementService.GetRole($Role)

        Write-Host -ForegroundColor Yellow "STARTING: Removing member from role" $K2Role.Name                

        $FoundMemberInclude = $null
        foreach($Member in $K2Role.Include)
        {
            if ($Member.Name.ToLower() -eq $RoleMember.ToLower()) {
                $FoundMemberInclude = $Member
                break
            }
        }

        if ($FoundMemberInclude -ne $null) {
            $K2Role.Include.Remove($FoundMemberInclude)
        }

        $FoundMemberExclude = $null
        foreach($Member in $K2Role.Exclude) {
            if ($Member.Name.ToLower() -eq $RoleMember.ToLower()) {
                $FoundMemberExclude = $Member
                break
            }
        }

        if ($FoundMemberExclude -ne $null) {
            $K2Role.Exclude.Remove($FoundMemberExclude)
        }

        $K2Role.ExpiryDate = [System.DateTime]::Now

        $RoleManagementService.UpdateRole($K2Role)


        Write-Host -ForegroundColor Green "FINISHED: Removing member from role" $Role
    
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null

    }
}

function Get-K2RoleMember {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Role,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$RoleMember
    )

    process {

        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString

        $K2Role = $RoleManagementService.GetRole($Role)

        Write-Host -ForegroundColor Yellow "STARTING: Get Role Member from role" $K2Role.Name                

        $FoundMember = $null

        foreach ($Member in $K2Role.Include) {
            if ($Member.Name.ToLower() -eq $RoleMember.ToLower()) {
                $FoundMember = "include"
                break
            }
        }

        foreach ($Member in $K2Role.Exclude) {
            if ($Member.Name.ToLower() -eq $RoleMember.ToLower()) {
                $FoundMember = "exclude"
                break
            }
        }


        Write-Host -ForegroundColor Green "FINISHED: Get Role Member from role" $Role
    
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null

        Write-Output $FoundMember

    }
}



function Get-K2WorkflowManagementServer {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2WorkflowConnectionString
    )

    process {
        Add-Type -Path (Get-K2BlackPearlDirectory + "\Bin\SourceCode.Workflow.Management.dll")
        $WFManagementService = New-Object SourceCode.Workflow.Management.WorkflowManagementServer

        #Create connection and capture output (methods return a bool)
        $tmpOut = $WFManagementService.CreateConnection()
        $tmpOut = $WFManagementService.Connection.Open($K2WorkflowConnectionString);

        Write-Output $WFManagementService
    }
}


function New-K2WorkflowUserPermission {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2WorkflowConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Workflow,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$UserFQN,
        [Parameter(Mandatory=$true,Position=3)]
        [bool]$Admin,
        [Parameter(Mandatory=$true,Position=4)]
        [bool]$Start,
        [Parameter(Mandatory=$true,Position=5)]
        [bool]$View,
        [Parameter(Mandatory=$true,Position=6)]
        [bool]$ViewParticipate,
        [Parameter(Mandatory=$true,Position=7)]
        [bool]$ServerEvent

    )

    process {
        $WFManagementService = Get-K2WorkflowManagementServer -K2WorkflowConnectionString $K2WorkflowConnectionString
        

        $ProcSet = $WFManagementService.GetProcSet($Workflow);

        $Process = $WFManagementService.GetProcess($ProcSet.ProcID);

        Write-Host -ForegroundColor Yellow "STARTING: Adding user permissions to workflow:" $Process.FullName               

        #$Filter = New-Object SourceCode.Workflow.Management.Criteria.ProcSetPermissionsCriteriaFilter
        $CurrentPermissions = $WFManagementService.GetProcessUserPermissions($Process.ProcSetID);


        $ExistingPermissions = $null

        $CurrentPermissions | foreach {            
            
            if ($_.UserName = $UserFQN)
            {
                $ExistingPermissions = $_         
            }

        }

        if ($ExistingPermissions -ne $null)
        {
            #Update existing permission

            $ExistingPermissions.Admin = $Admin
            $ExistingPermissions.Start = $Start
            $ExistingPermissions.View = $View
            $ExistingPermissions.ViewPart = $ViewParticipate
            $ExistingPermissions.ServerEvent = $ServerEvent

        }
        else 
        {
            #Create new permissions
            
            $ExistingPermissions = New-Object SourceCode.Workflow.Management.ProcSetPermissions            
            $ExistingPermissions.UserName = $UserFQN.ToUpper()
            $ExistingPermissions.ProcessFullName = $Process.FullName
            $ExistingPermissions.ProcSetID = $Process.ProcSetID
            $ExistingPermissions.Admin = $Admin
            $ExistingPermissions.Start = $Start
            $ExistingPermissions.View = $View
            $ExistingPermissions.ViewPart = $ViewParticipate
            $ExistingPermissions.ServerEvent = $ServerEvent

        }
        
        $CurrentPermissions.Add($ExistingPermissions)

        $WFManagementService.UpdateOrAddProcUserPermissions($Process.ProcSetID, $CurrentPermissions)

        Write-Host -ForegroundColor Green "FINISHED: Adding user permissions to workflow: " $CurrentPermissions.Count
    
        $WFManagementService.Connection.Close();
        $WFManagementService = $null
        $Process = $null
        $ProcSet = $null
        $ExistingPermissions = $null
        $CurrentPermissions = $null
    }
}


function New-K2WorkflowGroupPermission {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$K2WorkflowConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Workflow,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$GroupFQN,
        [Parameter(Mandatory=$true,Position=3)]
        [bool]$Admin,
        [Parameter(Mandatory=$true,Position=4)]
        [bool]$Start,
        [Parameter(Mandatory=$true,Position=5)]
        [bool]$View,
        [Parameter(Mandatory=$true,Position=6)]
        [bool]$ViewParticipate,
        [Parameter(Mandatory=$true,Position=7)]
        [bool]$ServerEvent

    )

    process {
        $WFManagementService = Get-K2WorkflowManagementServer -K2WorkflowConnectionString $K2WorkflowConnectionString
        

        $ProcSet = $WFManagementService.GetProcSet($Workflow);

        $Process = $WFManagementService.GetProcess($ProcSet.ProcID);

        Write-Host -ForegroundColor Yellow "STARTING: Adding group permissions to workflow:" $Process.FullName               

        #$Filter = New-Object SourceCode.Workflow.Management.Criteria.ProcSetPermissionsCriteriaFilter
        $CurrentPermissions = $WFManagementService.GetProcessGroupPermissions($Process.ProcSetID);


        $ExistingPermissions = $null

        $CurrentPermissions | foreach {            
            
            if ($_.UserName = $GroupFQN)
            {
                $ExistingPermissions = $_         
            }

        }

        if ($ExistingPermissions -ne $null)
        {
            #Update existing permission

            $ExistingPermissions.Admin = $Admin
            $ExistingPermissions.Start = $Start
            $ExistingPermissions.View = $View
            $ExistingPermissions.ViewPart = $ViewParticipate
            $ExistingPermissions.ServerEvent = $ServerEvent

        }
        else 
        {
            #Create new permissions
            
            $ExistingPermissions = New-Object SourceCode.Workflow.Management.ProcSetPermissions            
            $ExistingPermissions.GroupName = $GroupFQN.ToUpper()
            $ExistingPermissions.ProcessFullName = $Process.FullName
            $ExistingPermissions.ProcSetID = $Process.ProcSetID
            $ExistingPermissions.Admin = $Admin
            $ExistingPermissions.Start = $Start
            $ExistingPermissions.View = $View
            $ExistingPermissions.ViewPart = $ViewParticipate
            $ExistingPermissions.ServerEvent = $ServerEvent

        }
        
        $CurrentPermissions.Add($ExistingPermissions)

        $WFManagementService.UpdateProcGroupPermissions($Process.ProcSetID, $CurrentPermissions)

        Write-Host -ForegroundColor Green "FINISHED: Adding group permissions to workflow: " $CurrentPermissions.Count
    
        $WFManagementService.Connection.Close();
        $WFManagementService = $null
        $Process = $null
        $ProcSet = $null
        $ExistingPermissions = $null
        $CurrentPermissions = $null
    }
}
