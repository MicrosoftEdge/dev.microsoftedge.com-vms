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

param([string]$uri)

C:\Windows\System32\icacls.exe "C:\Users\IEUser" /grant "IEUser:(OI)(CI)F"
C:\Windows\System32\icacls.exe "C:\windows\temp" /grant "IEUser:(OI)RX"
C:\Windows\System32\icacls.exe "C:\windows\temp" /grant "IEUser:(OI)RX"
Write-Output "Downloading IE SETUP from $uri"
(New-Object System.Net.WebClient).DownloadFile($uri, "C:\Windows\Temp\ie_setup.exe")
Write-Output "Running ie_setup..."
$iesetup = "C:\Windows\Temp\ie_setup.exe"
$arguments = "/quiet /update-no /closeprograms /log:c:\windows\temp /norestart"
$password = "Passw0rd!"  | ConvertTo-SecureString -asPlainText -F
$username = ".\IEUser"
$credentials = New-Object System.Management.Automation.PSCredential($username,$password)
Start-Process $iesetup $arguments  -Wait -Credential $credentials
Write-Output "IE Setup finished Done!"