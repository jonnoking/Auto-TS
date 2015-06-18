# Disable Execution Policy
Set-ExecutionPolicy Unrestricted

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Write-Host -ForegroundColor Cyan "----- POST TEST EXECTUTED -----"