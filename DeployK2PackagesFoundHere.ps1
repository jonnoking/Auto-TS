# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

$Continue = Read-Host -Prompt "This script will deploy all K2 Packages (*.KSPX) in this directory. It may overwrite existing assets. Please use the K2 Package and Deployment tool if you are unsure. Do you wish to continue? (Yes [Y] | No [N]) "
if ($Continue -ne "Y" -and $Continue -ne "Yes")
{
    Write-Host "The script has stopped at your request."
    return
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

set-alias installutil $env:windir\Microsoft.NET\Framework64\v4.0.30319\installutil | Out-Null
installutil -u /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL' | Out-Null
installutil -i /AssemblyName 'SourceCode.Deployment.PowerShell, Version=4.0.0.0, Culture=neutral, PublicKeyToken=16a2c5aaaa1b130d, processorArchitecture=MSIL' | Out-Null
Add-PSSnapin SourceCode.Deployment.PowerShell


#Get K2 Connection String
$K2ConnectionString = Get-K2ConnectionString

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Write-Host "Packages Found: "( Get-ChildItem $ScriptPath"\*" -Include *.kspx | Measure-Object ).Count -ForegroundColor Green;

Get-ChildItem -Path $ScriptPath"\*" -Include *.kspx | 
Foreach-Object{
    #foreach KSPX found deploy package   

    # NoAnalyze - will overwrite all objects
    #Deploy-Package ($_.FullName) -ConnectionString $K2ConnectionString.ConnectionString -NoAnalyze -ErrorAction Inquire    

    Deploy-Package ($_.FullName) -ConnectionString $K2ConnectionString.ConnectionString -ErrorAction Inquire    
}

$K2ConnectionString = $null



 