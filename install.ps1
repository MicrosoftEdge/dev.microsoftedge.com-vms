# --------------------------------------------------------------
#
#  dev.microsoftedge.com -VMs
#  Copyright(c) Microsoft Corporation. All rights reserved.
#
#  MIT License
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files(the ""Software""),
#  to deal in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
#  of the Software, and to permit persons to whom the Software is furnished to do so,
#  subject to the following conditions :
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
#  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS
#  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
#  OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# --------------------------------------------------------------

Write-Output "Downloading all tools"

function Download {
	param (
		[string]$url,
		[string]$output
	)

	$start_time = Get-Date
	(New-Object System.Net.WebClient).DownloadFile($url, $output)
	Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

function Install-Putty {
	Write-Output "Downloading and installing Putty"
	New-Item -ItemType Directory -Force -Path "$PSScriptRoot\bin\Putty\" | Out-Null
	Download -url "https://the.earth.li/~sgtatham/putty/latest/x86/putty.exe" -output "$PSScriptRoot\bin\Putty\putty.exe"
}

function Install-AzCopy {
	Write-Output "Downloading and installing AzCopy"
	$path = "$PSScriptRoot\bin"
	New-Item -ItemType Directory -Force -Path $path | Out-Null
	Download -url "http://aka.ms/downloadazcopy" -output "$path\azcopy-installer.msi"
	Start-Process msiexec -ArgumentList "/a $output /qb TARGETDIR=$path\AzCopy /quiet" -Wait
	Copy-Item -Path "$path\AzCopy\Microsoft SDKs\Azure\AzCopy\*.*" -Destination "$path\AzCopy" -Recurse
	Remove-Item -Recurse -Force "$path\AzCopy\Microsoft SDKs"
	Remove-Item -Recurse -Force $output
}

function Build-Project {
	param (
		[string]$name
	)

	Write-Output "Building $name"
	Start-Process "$PSScriptRoot\bin\nuget.exe" -ArgumentList "restore $PSScriptRoot\tools\$name\$name.sln" -Wait
	Start-Process msbuild -ArgumentList "$PSScriptRoot\tools\$name\$name\$name.csproj /t:Build" -Wait
}

function Build-Projects {
	Build-Project -name "PackerMerge"
	Build-Project -name "VMSGen"
}

function Install-Packer {
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	Write-Output "Downloading Packer.io"
	$packer = "$PSScriptRoot\bin\packer.zip"
	Remove-Item -Recurse -Force $packer
	Download -url "https://releases.hashicorp.com/packer/0.10.2/packer_0.10.2_windows_amd64.zip" -output $packer
	[System.IO.Compression.ZipFile]::ExtractToDirectory($packer, "C:\packer\")
}

function Install-Build-Tools2 {
	Write-Output "Installing .Net Framework 4.6"
	choco install dotnet4.6 -y

	Write-Output "Installing .Net Framework 4.6 Target"
	choco install dotnet4.6-targetpack -y

	Write-Output "Installing MSBuild"
	choco install microsoft-build-tools -y

	Write-Output "Installing nuget"
	choco install nuget.commandline
}

function Install-Chocolatey {
	iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
}

function Install-Dependencies {
	$dependencies = @("dotnet4.6", "dotnet4.6-targetpack", "microsoft-build-tools", "nuget.commandline", "azcopy", "putty.portable")
	foreach($dependency in $dependencies){
		Write-Output "Installing $dependency"
		choco install $dependency -y
	}
}

#Install-Putty
#Install-AzCopy
Install-Chocolatey
#Install-Build-Tools
Install-Dependencies
Build-Projects
#Install-Packer

