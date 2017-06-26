Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#Packer 1.0.0
cinst packer -y
# VirtualBox 5.1.22 for Windows hosts
cinst virtualbox -y
# VMware Workstation 12.5.6
cinst vmwareworkstation -y
# 7-Zip 16.4.0 for Windows 64bits
cinst 7zip -y
# AzCopy 3.1.0
cinst azcopy -y
#move the azcopy binaries to the bin folder
$AzPath = ${Env:ProgramFiles(x86)} + "\Microsoft SDKs\Azure\AzCopy"
$Destination = "..\..\bin\AzCopy"
if(Test-Path $Destination){
    Remove-Item $Destination -recurse
}
New-Item $Destination -Type Directory
Copy-Item $AzPath\*  $Destination
# Putty
cinst putty.install -y
#move the putty binaries to the bin folder
$PuttyPath = ${Env:ProgramFiles} + "\PuTTY"
$Destination = "..\..\bin\putty"
if(Test-Path $Destination){
    Remove-Item $Destination -recurse
}
New-Item $Destination -Type Directory
Copy-Item $PuttyPath\*  $Destination
# Visual Studio 2015 Community
cinst visualstudio2015community -y