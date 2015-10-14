@ECHO OFF
SET CURRENTDIR=%CD%

PowerShell.exe -NoProfile -file "%CURRENTDIR%\DeployK2PackagesFoundHere.ps1" -path "%CURRENTDIR%"

pause