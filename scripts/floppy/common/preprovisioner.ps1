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

param (
  [Int]$IEBlocker = 0,
  [String]$IESetupUrl = ""
)

# Install updates on the next restart
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$RegistryEntry = "InstallWindowsUpdates"
$UpdateScriptPath = "a:\win-updates.ps1"
Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File $($UpdateScriptPath)"

# Set IEBlocker Registry Key

[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$json = Get-Content "A:\build.cfg"
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$config = $ser.DeserializeObject($json)

$build = $config.build
$windows = $config.windows
$ie = $config.ie


$ieNumber = $ie.Substring(2)
$IEBlocker = [int]$IENumber + 1

# Change Computer Name
#Rename-Computer -NewName "$ie$windows"

$IEBlocker8Key = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Setup\8.0"
$IEBlocker8Value = "DoNotAllowIE80"

$IEBlocker9Key = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Setup\9.0"
$IEBlocker9Value = "DoNotAllowIE90"

$IEBlocker10Key = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Setup\10.0"
$IEBlocker10Value = "DoNotAllowIE10"

$IEBlocker11Key = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Setup\11.0"
$IEBlocker11Value = "DoNotAllowIE11"


switch ($IEBlocker) {
    7 {
        Write-Output "Blocking IE7-IE11"
        New-Item -Path $IEBlocker7Key -Force
        New-ItemProperty -Path $IEBlocker7Key -Name $IEBlocker7Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker8Key -Force
        New-ItemProperty -Path $IEBlocker8Key -Name $IEBlocker8Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker9Key -Force
        New-ItemProperty -Path $IEBlocker9Key -Name $IEBlocker9Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker10Key -Force
        New-ItemProperty -Path $IEBlocker10Key -Name $IEBlocker10Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker11Key -Force
        New-ItemProperty -Path $IEBlocker11Key -Name $IEBlocker11Value -PropertyType DWord -Value 1 -Force
    }
    8 {
        Write-Output "Blocking IE8-IE11"
        New-Item -Path $IEBlocker8Key -Force
        New-ItemProperty -Path $IEBlocker8Key -Name $IEBlocker8Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker9Key -Force
        New-ItemProperty -Path $IEBlocker9Key -Name $IEBlocker9Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker10Key -Force
        New-ItemProperty -Path $IEBlocker10Key -Name $IEBlocker10Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker11Key -Force
        New-ItemProperty -Path $IEBlocker11Key -Name $IEBlocker11Value -PropertyType DWord -Value 1 -Force
    }
    9 {
        Write-Output "Blocking IE9-IE11"
        New-Item -Path $IEBlocker9Key -Force
        New-ItemProperty -Path $IEBlocker9Key -Name $IEBlocker9Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker10Key -Force
        New-ItemProperty -Path $IEBlocker10Key -Name $IEBlocker10Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker11Key -Force
        New-ItemProperty -Path $IEBlocker11Key -Name $IEBlocker11Value -PropertyType DWord -Value 1 -Force
    }
    10 {
        Write-Output "Blocking IE10-IE11"
        New-Item -Path $IEBlocker10Key -Force
        New-ItemProperty -Path $IEBlocker10Key -Name $IEBlocker10Value -PropertyType DWord -Value 1 -Force
        New-Item -Path $IEBlocker11Key -Force
        New-ItemProperty -Path $IEBlocker11Key -Name $IEBlocker11Value -PropertyType DWord -Value 1 -Force
    }
    11 {
        Write-Output "Blocking IE11"
        New-Item -Path $IEBlocker11Key -Force
        New-ItemProperty -Path $IEBlocker11Key -Name $IEBlocker11Value -PropertyType DWord -Value 1 -Force
    }

    0 {
        Write-Output "IE Blocker not installed"
    }
}

# Copy EULA to system32
Copy-Item A:\eula.txt C:\Windows\System32

# Create EULA Shortcut
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\eula.lnk")
$Shortcut.TargetPath = "C:\windows\system32\eula.txt"
$Shortcut.Save()

Restart-Computer -Force