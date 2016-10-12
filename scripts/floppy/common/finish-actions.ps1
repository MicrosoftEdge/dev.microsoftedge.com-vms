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


[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$json = Get-Content "A:\build.cfg"
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$config = $ser.DeserializeObject($json)
$software = $config.software
$windows = $config.windows
copy a:\build.cfg C:\bginfo

# Change Browsers Home Page
& A:\browser-homepage.ps1

# Start WinRM
If ($windows -eq "Win10" -or $windows -eq "Win81") {
    & A:\start-winrm.ps1
}

# Copy SSH to execute
copy a:\openssh.ps1 C:\bginfo

$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$RegistryEntry = "FinishInstallActions"
$ScriptPath = "c:\bginfo\openssh.ps1"

Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File $($script:ScriptPath)"

Restart-Computer -Force
