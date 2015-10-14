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



#[List Method] 1. SharePoint_Integration_Workflow_Helper_Methods.LoadPackage(string siteUrl, string siteName, string listName string ListId, file packageFile) -> string Result (which will be the session name and required for all future methods)
#[List Method] 2. SharePoint_Integration_Workflow_Helper_Methods.RefactorSharepointArtifacts(string Result(session name), string siteUrl, string siteName, string listName string ListId) -> String Result
#[List Method] 3. SharePoint_Integration_Workflow_Helper_Methods.RefactorModel(string Result(session name), string siteUrl, string siteName, string listName string ListId) -> String Result
#[Scalar Method] [TAKES ALONG TIME] 4. SharePoint_Integration_Workflow_Helper_Methods.AutoResolve(string Result(session name), string siteUrl, string siteName, string listName string ListId) -> String Result
#[List Method] 5. SharePoint_Integration_Workflow_Helper_Methods.DeployPackage(string Result(session name)) -> String Result, String ConflictMessage(if there are any)
#[CAT: Package and Deployment - Progress - Get Progress] 6. Progress.GetProgress(string sessionName, “Deploy”) -> int NumberOfItemsProcessed, int TotalNumberOfItemsToProcess
#7. [Optional] File_Handler.DownloadDeploymentLog(string sessionName, “.log”) -> File DeploymentLog


#0 Deploy SP Package
function Deploy-K2SharePointPackage {
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

        $SessionName = Set-K2SmOSPLoadPackage -SiteUrl $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -PackagePath $PackagePath
        $s1 = Set-K2SmOSPRefactorSharepointArtifacts -SiteUrl $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SessionName $SessionName
        $s1 = Set-K2SmOSPRefactorModel $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SessionName $SessionName
        $s1 = Set-K2SmOSPAutoResolve $SiteUrl -SiteName $SiteName -ListName $ListName -ListId $ListId -SessionName $SessionName
        $s1 = Set-K2SmODeployPackage -SessionName $SessionName        

        # Deploy package is asynchronous - need to call Get-K2SmOSPCheckDeploymentStatus to check status
        # Post deployment success need to call Get-K2SmOSPCloseDeploymentSession to close deployment session

        


        Write-Output $SessionName

    }
    END
    {
        

    }
}


#1
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
        #$PackageSmartFileXml = Get-K2SmoFileProperty -Name "PackageFile" -DisplayName "Package File" -Filename $PackageFilename -Base64 $PackageBase64

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
        $SmoClient = $null

    }
}


#2
function Set-K2SmOSPRefactorSharepointArtifacts {
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
        [string]$SessionName
    )

    process {
    
        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods")

        $SPHelperSmo.ListMethods["RefactorSharePointArtifacts"].InputProperties["k2_Int_Result"].Value = $SessionName;
        $SPHelperSmo.ListMethods["RefactorSharePointArtifacts"].InputProperties["SiteUrl"].Value = $SiteUrl;
        $SPHelperSmo.ListMethods["RefactorSharePointArtifacts"].InputProperties["SiteName"].Value = $SiteName;
        $SPHelperSmo.ListMethods["RefactorSharePointArtifacts"].InputProperties["ListName"].Value = $ListName;
        $SPHelperSmo.ListMethods["RefactorSharePointArtifacts"].InputProperties["ListId"].Value = $ListId;
        $SPHelperSmo.MethodToExecute = "RefactorSharePointArtifacts"

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
        $SmoClient = $null
    }
}


#3 - almost exactly the same as RefactorSharePointArtifacts
function Set-K2SmOSPRefactorModel {
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
        [string]$SessionName
    )

    process {
      
        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods")

        $SPHelperSmo.ListMethods["RefactorModel"].InputProperties["k2_Int_Result"].Value = $SessionName;
        $SPHelperSmo.ListMethods["RefactorModel"].InputProperties["SiteUrl"].Value = $SiteUrl;
        $SPHelperSmo.ListMethods["RefactorModel"].InputProperties["SiteName"].Value = $SiteName;
        $SPHelperSmo.ListMethods["RefactorModel"].InputProperties["ListName"].Value = $ListName;
        $SPHelperSmo.ListMethods["RefactorModel"].InputProperties["ListId"].Value = $ListId;
        $SPHelperSmo.MethodToExecute = "RefactorModel"

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
        $SmoClient = $null
    }
}


#4
function Set-K2SmOSPAutoResolve {
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
        [string]$SessionName
    )

    process {
       
        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods")

        $SPHelperSmo.Methods["AutoResolve"].InputProperties["k2_Int_Result"].Value = $SessionName;
        $SPHelperSmo.Methods["AutoResolve"].InputProperties["SiteUrl"].Value = $SiteUrl;
        $SPHelperSmo.Methods["AutoResolve"].InputProperties["SiteName"].Value = $SiteName;
        $SPHelperSmo.Methods["AutoResolve"].InputProperties["ListName"].Value = $ListName;
        $SPHelperSmo.Methods["AutoResolve"].InputProperties["ListId"].Value = $ListId;
        $SPHelperSmo.MethodToExecute = "AutoResolve"

        #$LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $LoadPackageResultSmo = $SmoClient.ExecuteScalar($SPHelperSmo)        

        $SessionName = $LoadPackageResultSmo.Properties["k2_Int_Result"].Value;

        if ($SessionName -eq "") {
            #FAIL
        }

        Write-Output $SessionName

    }
    END
    {
        $SmoClient.Connection.Close()
        $SmoClient = $null
    }
}


#5
function Set-K2SmODeployPackage {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$SessionName
    )

    process {

        
        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods")

        $SPHelperSmo.ListMethods["DeployPackage"].InputProperties["k2_Int_Result"].Value = $SessionName;

        $SPHelperSmo.MethodToExecute = "DeployPackage"

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
        $SmoClient = $null
    }
}


#6
function Get-K2SmOSPCheckDeploymentStatus {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$SessionName
    )

    process {

        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("Progress")

        $SPHelperSmo.Methods["GetProgress"].InputProperties["SessionName"].Value = $SessionName;
        $SPHelperSmo.Methods["GetProgress"].InputProperties["Type"].Value = "Deploy";
        $SPHelperSmo.MethodToExecute = "GetProgress"

        #$LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $LoadPackageResultSmo = $SmoClient.ExecuteScalar($SPHelperSmo)        

        $NumberOfItemsProcessed = [int]$LoadPackageResultSmo.Properties["NumberOfItemsProcessed"].Value;
        $TotalNumberOfItems = [int]$LoadPackageResultSmo.Properties["TotalNumberOfItemsToProcess"].Value;

        if ($NumberOfItemsProcessed -lt $TotalNumberOfItems) {
            Write-Output "DEPLOYING"
        } else {
            Write-Output "DEPLOYED"
        }


    }
    END
    {
        $SmoClient.Connection.Close()
        $SmoClient = $null
    }
}
#7
function Close-K2SmOSPDeploymentSession {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$SessionName
    )

    process {

        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("Session_PackagingDeploymentService")

        $SPHelperSmo.Methods["Close"].InputProperties["Name"].Value = $SessionName;
        $SPHelperSmo.MethodToExecute = "Close"

        #$LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $LoadPackageResultSmo = $SmoClient.ExecuteScalar($SPHelperSmo)        

        #$NumberOfItemsProcessed = $LoadPackageResultSmo.Properties["NumberOfItemsProcessed"].Value;

        #if ($SessionName -eq "") {
            #FAIL
        #}

        #Write-Output $NumberOfItemsProcessed

    }
    END
    {
        $SmoClient.Connection.Close()
        $SmoClient = $null
    }
}

#####
##### DELETE ALL K2 ARTIFACTS FROM LIST/LIBRARY

#1 - GET ID - SharePoint Integration Setting.LoadWithoutId(ListId) Returns Id Guid
#2 - RESET - SharePoint Integration Setting.Rest(Id) - DOESN'T ACTUALLY DELETE THE K2 ASSETS


#<brokerpackage><smartobject name="portal_denallix_com_Management_Event" guid="16311fe7-7df0-4256-a46a-5aecb3c16132" version="9" resultname=""><property name="ListId"><value>eecc5ac4-99a6-4e05-94a2-e7781b3df8de</value></property><property name="K2_Int_SubSiteRelativeUrl"><value>/denallix-bellevue</value></property><property name="RemoteReceiverTypes"><value>10001;</value></property><method name="RemoveSpecificEvents" /></smartobject></brokerpackage>
#<brokerpackage><smartobject name="SharePoint_Integration_Workflow" guid="30db085b-ed82-44da-812c-8ebefcd0141c" version="2" resultname=""><property name="WorkflowName"><value>Denallix-Bellevue Test Cal\Test Cal</value></property><property name="ListId"><value>eecc5ac4-99a6-4e05-94a2-e7781b3df8de</value></property><property name="DeleteRemoteEvents"><value>True</value></property><property name="SiteURL"><value>https://portal.denallix.com/denallix-bellevue</value></property><method name="Delete" /></smartobject></brokerpackage>
#<brokerpackage><smartobject name="SharePoint_Integration_Workflow_Helper_Methods" guid="f343a8d0-c7c6-4ad1-b72d-07ed5b568c46" version="2" resultname=""><property name="K2_Int_SiteUrl"><value>https://portal.denallix.com/denallix-bellevue</value></property><property name="IsDocLib"><value>false</value></property><property name="CategoryId"><value>30272</value></property><property name="IncludeReportForms"><value>true</value></property><method name="GetFormsPerCategoryAsCurrentUser" /></smartobject></brokerpackage>
#<brokerpackage><smartobject name="portal_denallix_com_Management_K2Application" guid="ff8f872a-27de-4055-9197-bdc521eb5ef0" version="10" resultname=""><property name="ListId"><value>eecc5ac4-99a6-4e05-94a2-e7781b3df8de</value></property><property name="K2_Int_SubSiteRelativeUrl"><value>/denallix-bellevue</value></property><method name="ResetListFormsUrl" /></smartobject></brokerpackage>
#<brokerpackage><smartobject name="SharePointIntegrationSetting_SharePoint_Integration" guid="6fd53e9f-021b-4e2e-bffa-809021bbbe5e" version="2" resultname=""><property name="Id"><value>8292dfb0-e891-4500-a486-7414c5e2460e</value></property><method name="Reset" /></smartobject></brokerpackage>
   

##### 
# TO DO - delete Event Receivers, delete workflows, delete forms & views


#0
function SET-K2SPRemoveK2ArtifactsFromList {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ListId
    )

    process {


        $K2ArtifactsResultSmo = Get-K2SmOSPGetK2ArtifactsId -ListId $ListId
        $ArtifactId = $K2ArtifactsResultSmo.Properties["Id"].Value;

        Set-K2SmOSPRemoveK2Artifacts -Id $ArtifactId

        Write-Output $true

    }
    END
    {
        
    }
}


#1
function Get-K2SmOSPGetK2ArtifactsId {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ListId
    )

    process {

        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePointIntegrationSetting_SharePoint_Integration")

        $SPHelperSmo.Methods["LoadWithoutId"].InputProperties["ListId"].Value = $ListId;
        $SPHelperSmo.MethodToExecute = "LoadWithoutId"

        #$LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $K2ArtifactsResultSmo = $SmoClient.ExecuteScalar($SPHelperSmo)        

        $ArtifactId = $K2ArtifactsResultSmo.Properties["Id"].Value;

        #if ($ArtifactId -eq "") {
            #FAIL
        #}

        Write-Output $K2ArtifactsResultSmo

    }
    END
    {
        $SmoClient.Connection.Close()
        $SmoClient = $null
    }
}


#2 - DOESN'T ACTUALLY DELETE THE K2 ASSETS
function Set-K2SmOSPRemoveK2Artifacts {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Id
    )

    process {

        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePointIntegrationSetting_SharePoint_Integration")

        $SPHelperSmo.Methods["Reset"].InputProperties["Id"].Value = $Id;
        $SPHelperSmo.MethodToExecute = "Reset"

        #$LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $RestResultSmo = $SmoClient.ExecuteScalar($SPHelperSmo)        


        #if ($SessionName -eq "") {
            #FAIL
        #}

        #Write-Output $ArtifactId

    }
    END
    {
        $SmoClient.Connection.Close()
        $SmoClient = $null
    }
}


#####


#####
##### GENERATE K2 Assets for a List - Works
function Set-K2SmOSPGenerateK2ArtifactsOnList {
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
        [string]$SourceUrl,
        [Parameter(Mandatory=$true,Position=5)]
        [string]$GenerateSmartForms,
        [Parameter(Mandatory=$true,Position=6)]
        [string]$SetFormsUrl,
        [Parameter(Mandatory=$true,Position=7)]
        [string]$GenerateReports
    )

    process {

        $SmoClient = Get-K2SmoClient        

        $SPHelperSmo = New-Object SourceCode.SmartObjects.Client.SmartObject

        $SPHelperSmo = $SmoClient.GetSmartObject("SharePoint_Integration_Workflow_Helper_Methods")

        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["K2_Int_SiteUrl"].Value = $SiteUrl;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["K2_Int_SiteTitle"].Value = $SiteName;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["K2_Int_ListId"].Value = $ListId;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["K2_Int_ListTitle"].Value = $ListName;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["K2_Int_SourceUrl"].Value = $SourceUrl;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["k2_Int_LinkSmOScope"].Value = "List/Library";
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["k2_Int_GenerateSmartForms"].Value = $GenerateSmartForms;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["k2_Int_SetFormsUrl"].Value = $SetFormsUrl;
        $SPHelperSmo.Methods["GenerateArtifactsForSharePointList"].InputProperties["k2_Int_GenerateReports"].Value = $GenerateReports;
        $SPHelperSmo.MethodToExecute = "GenerateArtifactsForSharePointList"

        #$LoadPackageList = $SmoClient.ExecuteList($SPHelperSmo).SmartObjectsList

        $RestResultSmo = $SmoClient.ExecuteScalar($SPHelperSmo)        


        #if ($SessionName -eq "") {
            #FAIL
        #}

        #Write-Output $ArtifactId

    }
    END
    {
        $SmoClient.Connection.Close()
        $SmoClient = $null
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

        $RefPath = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.SmartObjects.Services.Management.dll"
        Add-Type -Path  $RefPath
        
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
        $RefPath0 = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.HostClientAPI.dll"
        Add-Type -Path  $RefPath0

        $RefPath1 = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.SmartObjects.Services.Management.dll"
        Add-Type -Path  $RefPath1


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
          $managementServer = $null
        }

}


function New-K2ServiceType {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
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
        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }


        $SmoManagementService = Get-K2SmoManagementServer -K2ConnectionString $K2ConnectionString

        if ($ServiceTypeGuid -eq $null) {
            $NewServiceTypeGuid = ([System.Guid]::NewGuid())
        } else {
            $NewServiceTypeGuid = $ServiceTypeGuid
        }

        Write-Host -ForegroundColor Yellow "STARTING: Registering service type" $ServiceTypeDisplayName

        $tmpOut = $SmoManagementService.RegisterServiceType($NewServiceTypeGuid, $ServiceTypeSystemName, $ServiceTypeDisplayName, $ServiceTypeDescription, $ServiceTypeAssemblyPath, $ServiceTypeClass);

        Write-Host -ForegroundColor Green "FINISHED: Registering service type" $ServiceTypeDisplayName
    
    }
    END
    {
        $SmoManagementService.Connection.Close();
        $SmoManagementService = $null
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

        $RefPath = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.SmartObjects.Services.Management.dll"
        Add-Type -Path  $RefPath

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
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString
    )

    process {
        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        $RefPath = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.Security.UserRoleManager.Management.dll"
        Add-Type -Path  $RefPath

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
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Name,        
        [Parameter(Mandatory=$True,Position=2)]
        [string]$DefaultRoleMember,        
        [Parameter(Mandatory=$True,Position=3)]
        [string]$DefaultRoleMemberType,        
        [Parameter(Mandatory=$false,Position=4)]
        [string]$Description,        
        [Parameter(Mandatory=$false,Position=5)]
        [string]$IsDynamic,        
        [Parameter(Mandatory=$false,Position=6)]
        [int]$RefreshInterval        
    )

    process {
        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        Write-Host -ForegroundColor Yellow "STARTING: Creating Role " $Name                

        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString

        $K2Role = $null
        
        $K2Role = $RoleManagementService.GetRole($Name)

        if ($K2Role -eq $null) {

            # K2 Role doesn't already exists
            $K2Role = New-Object SourceCode.Security.UserRoleManager.Management.Role

            $K2Role.Name = $Name
            $K2Role.Description = $Description
            $K2Role.IsDynamic = $IsDynamic

            if ($RefreshInterval > 0) {
                $K2Role.Interval = $RefreshInterval
            }


            $RoleItem = $null

            switch($DefaultRoleMemberType.ToLower())
            {
                "user" 
                    {
                        $NewItem = New-Object SourceCode.Security.UserRoleManager.Management.UserItem
                        $NewItem.Name = $DefaultRoleMember.ToUpper()
                        $RoleItem = $NewItem
                    }
                "group"
                    {
                        $NewItem = New-Object SourceCode.Security.UserRoleManager.Management.GroupItem
                        $NewItem.Name = $DefaultRoleMember.ToUpper()
                        $RoleItem = $NewItem
                    }
            }

            $K2Role.Include.Add($RoleItem)
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
    
    }
    END
    {
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}

function Get-K2RoleExists {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
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

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        Write-Host -ForegroundColor Green "STARTING: Check if Role Exists " $Name
        
        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString


        $K2Role = $null
        
        $K2Role = $RoleManagementService.GetRole($Name)


        Write-Host -ForegroundColor Green "FINISHED: Check if Role Exists " $Name
    

        if ($K2Role -eq $null) {
            Write-Output $false
        } else {
            Write-Output $true
        }

    }
    END
    {
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}


function New-K2RoleMember {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
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

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        if ($IncludeExclude -eq "") {
            $IncludeExclude = "include"
        }

        $RoleManagementService = Get-K2RoleManagementServer -K2ConnectionString $K2ConnectionString


        $K2Role = $RoleManagementService.GetRole($Role)

        Write-Host -ForegroundColor Yellow "STARTING: Adding member to role" $K2Role.Name                

        # CHECK IF ROLEMEMBER ALREADY EXISTS
        $RMType = Get-K2RoleMember -Role $Role -RoleMember $RoleMember
        if ($RMType -ne "") {
            Delete-K2RoleMember -Role $Role -RoleMember $RoleMember
        }


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
    
    }
    END
    {
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}


function Delete-K2RoleMember {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Role,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$RoleMember
    )

    process {

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

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


    }
    END
    {
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}

function Get-K2RoleMember {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2ConnectionString,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Role,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$RoleMember
    )

    process {

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

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
    

        Write-Output $FoundMember

    }
    END
    {
        $RoleManagementService.Connection.Close();
        $RoleManagementService = $null
        $K2Role = $null
    }
}



function Get-K2WorkflowManagementServer {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$K2WorkflowConnectionString
    )

    process {

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

        $RefPath = Join-Path (Get-K2BlackPearlDirectory) -ChildPath "\Bin\SourceCode.Workflow.Management.dll"
        Add-Type -Path  $RefPath

        $WFManagementService = New-Object SourceCode.Workflow.Management.WorkflowManagementServer

        #Create connection and capture output (methods return a bool)
        $tmpOut = $WFManagementService.CreateConnection()
        $tmpOut = $WFManagementService.Connection.Open($K2ConnectionString);

        Write-Output $WFManagementService
    }
}


function New-K2WorkflowUserPermission {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Workflow,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$GroupFQN,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$Admin,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$Start,
        [Parameter(Mandatory=$true,Position=4)]
        [string]$View,
        [Parameter(Mandatory=$true,Position=5)]
        [string]$ViewParticipate,
        [Parameter(Mandatory=$true,Position=6)]
        [string]$ServerEvent,
        [Parameter(Mandatory=$false,Position=7)]
        [string]$K2WorkflowConnectionString

    )

    process {

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

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

            $ExistingPermissions.Admin = [System.Convert]::ToBoolean($Admin)
            $ExistingPermissions.Start = [System.Convert]::ToBoolean($Start)
            $ExistingPermissions.View = [System.Convert]::ToBoolean($View)
            $ExistingPermissions.ViewPart = [System.Convert]::ToBoolean($ViewParticipate)
            $ExistingPermissions.ServerEvent = [System.Convert]::ToBoolean($ServerEvent)

        }
        else 
        {
            #Create new permissions
            
            $ExistingPermissions = New-Object SourceCode.Workflow.Management.ProcSetPermissions            
            $ExistingPermissions.UserName = $UserFQN.ToUpper()
            $ExistingPermissions.ProcessFullName = $Process.FullName
            $ExistingPermissions.ProcSetID = $Process.ProcSetID
            $ExistingPermissions.Admin = [System.Convert]::ToBoolean($Admin)
            $ExistingPermissions.Start = [System.Convert]::ToBoolean($Start)
            $ExistingPermissions.View = [System.Convert]::ToBoolean($View)
            $ExistingPermissions.ViewPart = [System.Convert]::ToBoolean($ViewParticipate)
            $ExistingPermissions.ServerEvent = [System.Convert]::ToBoolean($ServerEvent)

        }
        
        $CurrentPermissions.Add($ExistingPermissions)

        $WFManagementService.UpdateOrAddProcUserPermissions($Process.ProcSetID, $CurrentPermissions)

        Write-Host -ForegroundColor Green "FINISHED: Adding user permissions to workflow: " $CurrentPermissions.Count

    }
    END
    {
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
        [string]$Workflow,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$GroupFQN,
        [Parameter(Mandatory=$true,Position=2)]
        [string]$Admin,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$Start,
        [Parameter(Mandatory=$true,Position=4)]
        [string]$View,
        [Parameter(Mandatory=$true,Position=5)]
        [string]$ViewParticipate,
        [Parameter(Mandatory=$true,Position=6)]
        [string]$ServerEvent,
        [Parameter(Mandatory=$false,Position=7)]
        [string]$K2WorkflowConnectionString

    )

    process {

        if ($K2ConnectionString -eq "") {
            $K2ConnectionString = Get-K2ConnectionString
        }

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

            $ExistingPermissions.Admin = [System.Convert]::ToBoolean($Admin)
            $ExistingPermissions.Start = [System.Convert]::ToBoolean($Start)
            $ExistingPermissions.View = [System.Convert]::ToBoolean($View)
            $ExistingPermissions.ViewPart = [System.Convert]::ToBoolean($ViewParticipate)
            $ExistingPermissions.ServerEvent = [System.Convert]::ToBoolean($ServerEvent)

        }
        else 
        {
            #Create new permissions
            
            $ExistingPermissions = New-Object SourceCode.Workflow.Management.ProcSetPermissions            
            $ExistingPermissions.GroupName = $GroupFQN.ToUpper()
            $ExistingPermissions.ProcessFullName = $Process.FullName
            $ExistingPermissions.ProcSetID = $Process.ProcSetID
            $ExistingPermissions.Admin = [System.Convert]::ToBoolean($Admin)
            $ExistingPermissions.Start = [System.Convert]::ToBoolean($Start)
            $ExistingPermissions.View = [System.Convert]::ToBoolean($View)
            $ExistingPermissions.ViewPart = [System.Convert]::ToBoolean($ViewParticipate)
            $ExistingPermissions.ServerEvent = [System.Convert]::ToBoolean($ServerEvent)

        }
        
        $CurrentPermissions.Add($ExistingPermissions)

        $WFManagementService.UpdateProcGroupPermissions($Process.ProcSetID, $CurrentPermissions)

        Write-Host -ForegroundColor Green "FINISHED: Adding group permissions to workflow: " $CurrentPermissions.Count
    
    }
    END
    {
        $WFManagementService.Connection.Close();
        $WFManagementService = $null
        $Process = $null
        $ProcSet = $null
        $ExistingPermissions = $null
        $CurrentPermissions = $null

    }
}


## From Paul Kelly
function Delete-AllProcesses
{
[CmdletBinding()]
                Param([string]$server,
                                  [int]$port)
                BEGIN
                {
                                $workflowManagementServer = Get-K2WorkflowManagementServer -server $server -port $port
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
