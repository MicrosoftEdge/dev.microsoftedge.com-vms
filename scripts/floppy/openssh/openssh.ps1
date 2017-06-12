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
  [switch]$AutoStart = $false,
  [switch]$Finish = $false
)

If (Test-Path c:\bginfo\software.txt) {
    $software = Get-Content c:\bginfo\software.txt
    $software = $software.Trim()
} Else {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $json = Get-Content "c:\bginfo\build.cfg"
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $config = $ser.DeserializeObject($json)
    $software = $config.software
}

function DownloadSSH () {
  Write-Output "AutoStart: $AutoStart"
  $is_64bit = [IntPtr]::size -eq 8

  # setup openssh
  $ssh_download_url = "http://www.mls-software.com/files/setupssh-6.7p1-2.exe"

  if (!(Test-Path "C:\Program Files\OpenSSH\bin\ssh.exe")) {
      Write-Output "Downloading $ssh_download_url"
      (New-Object System.Net.WebClient).DownloadFile($ssh_download_url, "C:\Windows\Temp\openssh.exe")

      # initially set the port to 2222 so that there is not a race
      # condition in which packer connects to SSH before we can disable the service
      Start-Process "C:\Windows\Temp\openssh.exe" "/S /port=2222 /privsep=1 /password=D@rj33l1ng" -NoNewWindow -Wait
  }

  Stop-Service "OpenSSHd" -Force

  # ensure vagrant can log in
  Write-Output "Setting vagrant user file permissions"
  New-Item -ItemType Directory -Force -Path "C:\Users\IEUser\.ssh"
  C:\Windows\System32\icacls.exe "C:\Users\IEUser" /grant "IEUser:(OI)(CI)F"
  C:\Windows\System32\icacls.exe "C:\Program Files\OpenSSH\bin" /grant "IEUser:(OI)RX"
  C:\Windows\System32\icacls.exe "C:\Program Files\OpenSSH\usr\sbin" /grant "IEUser:(OI)RX"

  Write-Output "Setting SSH home directories"
      (Get-Content "C:\Program Files\OpenSSH\etc\passwd") |
      Foreach-Object { $_ -replace '/home/(\w+)', '/cygdrive/c/Users/$1' } |
      Set-Content 'C:\Program Files\OpenSSH\etc\passwd'

  # Set shell to /bin/sh to return exit status
  $passwd_file = Get-Content 'C:\Program Files\OpenSSH\etc\passwd'
  $passwd_file = $passwd_file -replace '/bin/bash', '/bin/sh'
  Set-Content 'C:\Program Files\OpenSSH\etc\passwd' $passwd_file

  # fix opensshd to not be strict
  Write-Output "Setting OpenSSH to be non-strict"
  $sshd_config = Get-Content "C:\Program Files\OpenSSH\etc\sshd_config"
  $sshd_config = $sshd_config -replace 'StrictModes yes', 'StrictModes no'
  $sshd_config = $sshd_config -replace '#PubkeyAuthentication yes', 'PubkeyAuthentication yes'
  $sshd_config = $sshd_config -replace '#PermitUserEnvironment no', 'PermitUserEnvironment yes'
  # disable the use of DNS to speed up the time it takes to establish a connection
  $sshd_config = $sshd_config -replace '#UseDNS yes', 'UseDNS no'
  # disable the login banner
  $sshd_config = $sshd_config -replace 'Banner /etc/banner.txt', '#Banner /etc/banner.txt'
  # next time OpenSSH starts have it listen on th eproper port
  $sshd_config = $sshd_config -replace 'Port 2222', "Port 22"
  Set-Content "C:\Program Files\OpenSSH\etc\sshd_config" $sshd_config

  Write-Output "Removing ed25519 key as Vagrant net-ssh 2.9.1 does not support it"
  Remove-Item -Force -ErrorAction SilentlyContinue "C:\Program Files\OpenSSH\etc\ssh_host_ed25519_key"
  Remove-Item -Force -ErrorAction SilentlyContinue "C:\Program Files\OpenSSH\etc\ssh_host_ed25519_key.pub"

  # use c:\Windows\Temp as /tmp location
  Write-Output "Setting temp directory location"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "C:\Program Files\OpenSSH\tmp"
  C:\Program` Files\OpenSSH\bin\junction.exe /accepteula "C:\Program Files\OpenSSH\tmp" "C:\Windows\Temp"
  C:\Windows\System32\icacls.exe "C:\Windows\Temp" /grant "IEUser:(OI)(CI)F"

  # add 64 bit environment variables missing from SSH
  Write-Output "Setting SSH environment"
  $sshenv = "TEMP=C:\Windows\Temp"
  if ($is_64bit) {
      $env_vars = "ProgramFiles(x86)=C:\Program Files (x86)", `
          "ProgramW6432=C:\Program Files", `
          "CommonProgramFiles(x86)=C:\Program Files (x86)\Common Files", `
          "CommonProgramW6432=C:\Program Files\Common Files"
      $sshenv = $sshenv + "`r`n" + ($env_vars -join "`r`n")
  }
  Set-Content C:\Users\IEUser\.ssh\environment $sshenv

  # record the path for provisioners (without the newline)
  Write-Output "Recording PATH for provisioners"
  Set-Content C:\Windows\Temp\PATH ([byte[]][char[]] $env:PATH) -Encoding Byte

  # configure firewall
  Write-Output "Configuring firewall"
  netsh advfirewall firewall add rule name="SSHD" dir=in action=allow service=OpenSSHd enable=yes
  netsh advfirewall firewall add rule name="SSHD" dir=in action=allow program="C:\Program Files\OpenSSH\usr\sbin\sshd.exe" enable=yes
  netsh advfirewall firewall add rule name="ssh" dir=in action=allow protocol=TCP localport=22

  # Enable UAC
  #New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 1 -Force

  $RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
  $RegistryEntry = "FinishInstallActions"
  $ScriptPath = "c:\bginfo\openssh.ps1 -Finish"

  Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File $($ScriptPath)"

  Restart-Computer -Force
}

function OpenSSH () {
  #Start-Service "OpenSSHd"

#  If ($software -eq "HyperV" -or $software -eq "VPC") {
#    Stop-Computer -Force
#  }
}

If ($Finish -eq $true) {
   OpenSSH
} Else {
   DownloadSSH
}

