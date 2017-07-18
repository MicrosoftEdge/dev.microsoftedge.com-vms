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
  [switch]$Continue = $False,
  [switch]$Build = $False,
  [switch]$TestMode = $False,
  [switch]$Download = $False,
  [switch]$OnlyUpload = $False,
  [switch]$GenerateJSON = $True,
  [switch]$KeepOutput = $False,
  [int]$Instance = 1
)

Set-StrictMode -Version 3
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

$global:Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Set-Location $global:Path

$LogTime = Get-Date -Format "yyyyMMdd"
$Logfile = "$global:Path\vmgen_Instance_$Instance.log"

If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Verbose "Script is not run with administrative user"

  If ((Get-WmiObject Win32_OperatingSystem | select BuildNumber).BuildNumber -ge 6000) {
    $CommandLine = $MyInvocation.Line.Replace($MyInvocation.InvocationName, $MyInvocation.MyCommand.Definition)
    Write-Verbose "$CommandLine"
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "$CommandLine"

  } else {
    Write-Verbose "System does not support UAC"
    Write-Warning "This script requires administrative privileges. Please re-run with administrative account."
  }
  Break
}

function LogWrite {
   Param ([string]$logstring)
   $now = Get-Date -format s

   Add-Content $Logfile -value "$now $logstring"
   Write-Host "$now $logstring"
}

function Create-LockFile ($vms) {
    $vmslock = @()

    $vms |
    ForEach-Object {
        foreach ($property in ($_ | Get-Member -MemberType NoteProperty))
        {
            $os = $property.Name

            foreach ($property1 in ($_.$($property.Name) | Get-Member -MemberType NoteProperty))
            {
                $software = $property1.Name
                foreach ($property2 in ($_.$($property.Name).$($property1.Name) | Get-Member -MemberType NoteProperty))
                {
                    $browser = $property2.Name
                    $winVersions = $_.$($property.Name).$($property1.Name).$($property2.Name)

                    foreach ($winVersion in $winVersions)
                    {
                        $myObject2 = New-Object System.Object
                        $myObject2 | Add-Member -type NoteProperty -name OS -Value $os
                        $myObject2 | Add-Member -type NoteProperty -name Software -Value $software
                        $myObject2 | Add-Member -type NoteProperty -name Browser -Value $browser
                        $myObject2 | Add-Member -type NoteProperty -name Windows -Value $winVersion
                        $myObject2 | Add-Member -type NoteProperty -name Generated -Value $False
                        $myObject2 | Add-Member -type NoteProperty -name Failed -Value $False
                        $myObject2 | Add-Member -type NoteProperty -name Retried -Value $False
                        $myObject2 | Add-Member -type NoteProperty -name Start -Value $null
                        $myObject2 | Add-Member -type NoteProperty -name End -Value $null

                        $vmslock += $myObject2

                        LogWrite "- $os $software $browser $winVersion"
                    }
                }
            }
        }
    }

    $vmslock | ConvertTo-Json -depth 100 | Out-File "$global:Path\vmgen.json.lock"
    LogWrite "Lock file generated."
}

function Generate-BuildConfigurationFile ($software, $windows, $browser, $os) {
    If ($browser -eq "MSEdge") { $browser = "IE11" }

    If ($os -eq "Mac") { $path = "M:\scripts" }
    Else { $path = $global:Path }

    @{build=$global:buildId;windows=$windows;ie=$browser;software=$software} | ConvertTo-Json | Out-File "$path\floppy\build.cfg"

    LogWrite "Build configuration floppy file modified ($path)."
}

function Generate-Windows ($software, $windows, $browser, $os) {

       If ($TestMode -eq $True) {
           LogWrite "TESTMODE - Starting packer for Windows $software $windows $browser..."
           return
       }

       Generate-BuildConfigurationFile $software $windows $browser $os

       LogWrite "Starting packer for Windows $software $windows $browser..."


       If ($software -eq "VMware") {
            $only="vmware-iso"
       } ElseIf ($software -eq "VirtualBox") {
            $only="virtualbox-iso"
       } ElseIf ($software -eq "HyperV" -or $software -eq "VPC") {
            $only="hyperv-iso"
       }

       $data = $null
       $template = "$browser-$windows.json"
       Invoke-Expression "packer build -only=$only -color=false -force $global:Path\template-output\$template | Tee-Object -Variable data"
       $data | Out-File -File $Logfile -Append -Encoding Utf8

       if ($LASTEXITCODE -eq 1) {
            throw "Error creating VM with packer"
       }

       LogWrite "Packer generation finished $software $windows $browser..."
}

function Generate-Mac ($software, $windows, $browser, $os) {
       $networkPath = $global:Config.Mac.NetworkPath
       $SSHUser = $global:Config.Mac.SSH_User
       $SSHPassword = $global:Config.Mac.SSH_Password

       If (!(Test-Path M:))
       {
           Invoke-Expression "net use M: $networkPath /USER:$SSHUser $SSHPassword"
           LogWrite "Drive M mapped to $networkPath"
       }

       If ($TestMode -eq $True) {
           LogWrite "TESTMODE - Starting packer for Mac $software $windows $browser..."
           return
       }

       Generate-BuildConfigurationFile $software $windows $browser $os

       $macip = $global:Config.Mac.IP
       $macsshuser = $global:Config.Mac.SSH_User
       $macsshpass = $global:Config.Mac.SSH_Password
       $macRepoPath = $global:Config.Mac.RepoPath
       $macPackerPath = $global:Config.Mac.PackerPath
       LogWrite "Starting SSH session for packer for Mac $software $windows $browser..."

       $data = $null
       $template = "$browser-$windows.json"

       (Get-Content .\template-parts\parallels-command.template) |
       Foreach-Object {$_ -replace '{{template}}', $template}  |
       Foreach-Object {$_ -replace '{{path_repo}}', $macRepoPath}  |
       Foreach-Object {$_ -replace '{{path_packer}}', $macPackerPath}  |
       Out-File parallels-command.txt -Encoding ascii

       Invoke-Expression "..\bin\putty\plink -ssh $macsshuser@$macip -pw $macsshpass -batch -m parallels-command.txt | Tee-Object -Variable data"
       $data | Out-File -File $Logfile -Append -Encoding Utf8

       if ($LASTEXITCODE -eq 1) {
            throw "Error creating VM with packer"
       }
}

function Export ($software, $windows, $browser, $os) {
    If ($software -eq "VMware") {
        LogWrite "Exporting VMware machine to OVF..."
        & "${Env:ProgramFiles(x86)}/VMware/VMware Workstation/OVFTool/ovftool.exe" "$global:Path\..\vms\output\$browser-$windows-$software-vmx\$browser - $windows.vmx"  "$global:Path\..\vms\output\$browser-$windows-$software\$browser-$windows-$software.ovf"
        LogWrite "VM exported..."
    }

    If ($software -eq "VPC") {
        LogWrite "Exporting HyperV machine to VPC..."

        Move-Item "$global:Path\..\vms\output\$browser-$windows-HyperV" "$global:Path\..\vms\output\$browser-$windows-VPC"
        Move-Item "$global:Path\..\vms\output\$browser-$windows-$software\Virtual Hard Disks\$browser - $windows.vhdx" "$global:Path\..\vms\output\$browser-$windows-$software\"
        Remove-Item "$global:Path\..\vms\output\$browser-$windows-$software\Virtual Hard Disks\" -Force -recurse
        Remove-Item "$global:Path\..\vms\output\$browser-$windows-$software\Virtual Machines\" -Force -recurse
        Convert-VHD "$global:Path\..\vms\output\$browser-$windows-$software\$browser - $windows.vhdx" "$global:Path\..\vms\output\$browser-$windows-$software\$browser - $windows.vhd"

        $name = "$browser - $windows"
        $computer_name = "$browser$windows"

        (Get-Content .\template-parts\vpc.vmc.template) |
        Foreach-Object {$_ -replace '{{name}}', $name}  |
        Foreach-Object {$_ -replace '{{computer_name}}', $computer_name}  |
        Out-File "$global:Path\..\vms\output\$browser-$windows-$software\vpc.vmc" -Encoding ascii

        LogWrite "VM exported..."
    }
}

function GenerateLinux ($data) {
       throw "Linux Not implemented."
}

function Compress($software, $browser, $windows, $oshost) {

    $outputPath = $global:Config.OutputPath
    $zipFolder = "$outputPath\VMBuild_$global:buildId\$software\$browser\"
    $zipName = "$browser.$windows.$software.zip"

    If ($oshost -eq "Mac") { $source = "M:\scripts\$browser-$windows-$software\*.*" }
    Else { $source = "$global:Path\..\vms\output\$browser-$windows-$software\*.*" }

    LogWrite "Starting compression..."

    Compress-SingleAndMultipart $zipFolder $zipName $source

    If ($software -eq "VirtualBox") {

        LogWrite "Starting Vagrant compression..."
        # Compress Vagrant
        $zipFolder = "$outputPath\VMBuild_$global:buildId\Vagrant\$browser\"
        $zipName = "$browser.$windows.Vagrant.zip"

        $sourceBox = "$global:Path\..\vms\output\Vagrant\edgems.box"
        $source = "$global:Path\..\vms\output\Vagrant\$browser - $windows.box"
        If (Test-Path $sourceBox) { Move-Item $sourceBox $source -Force }

        Compress-SingleAndMultipart $zipFolder $zipName $source
    }
}

function Generate-Hashes ($zipsPath, $outputPath) {
    $files = Get-ChildItem $zipsPath -Recurse -Include *.zip,*.zip.*,*.gz
    foreach ($file in $files) {
        $hash = Get-FileHash $file -Algorithm MD5
        $filemd5 = $outputPath + "\" + $file.Name + ".md5.txt"
        New-Item $filemd5 -type file -force -value $hash.Hash
    }
}

function Compress-SingleAndMultipart ($zipFolder, $zipName, $source) {
    $multipart = $global:Config.GenerateMultipart

    IF(Test-Path $zipFolder) {
        Remove-Item "$zipFolder\*" -Force -Recurse
        LogWrite "Folder $zipFolder cleared."
    }

    $outputPath = $global:Config.OutputPath

    IF ($multipart -eq $True) {
      LogWrite "Compressing VM to multipart file ZIP $source $zipName in $zipFolder"
      & 7z a $zipFolder$zipName $source -tzip -r -v1G -aoa | Out-Null
    }

    LogWrite "Compressing VM to single file ZIP $source $zipName in $zipFolder"
    & 7z a $zipFolder$zipName $source -tzip -r -aoa | Out-Null

    $md5FolderPath = "$outputPath\md5\VMBuild_$global:buildId"
    LogWrite "Generating File Hashes..."
    Generate-Hashes $zipFolder $md5FolderPath
    LogWrite "MD5 File Hashes generated in $md5FolderPath."

    if($TestMode -eq $False){
        LogWrite "Removing output files..."
        Remove-Item $source -Recurse -Force  
    }
}

function Upload() {
    $outputPath = $global:Config.OutputPath
    $url = $global:Config.AzureStorage.Url
    $key = $global:Config.AzureStorage.Key
    $upload = $global:Config.AzureUpload

    if ($upload -eq $True) {
        LogWrite "Starting upload."
        # Upload Build
        ..\bin\AzCopy\AzCopy /Source:$outputPath\VMBuild_$global:buildId /Dest:$url/VMBuild_$global:buildId /DestKey:$key /S /Y

        # Upload MD5
        ..\bin\AzCopy\AzCopy /Source:$outputPath\md5\VMBuild_$global:buildId /Dest:$url/md5\VMBuild_$global:buildId /DestKey:$key /S /Y

        LogWrite "Upload finished."

    } else {
        LogWrite "Skipping upload to Azure storage."
    }
}

function Remove-OutputFiles () {
    $outputPath = $global:Config.OutputPath

    if($KeepOutput -eq $False){
        Remove-Item $outputPath\VMBuild_$global:buildId -recurse -Force
        LogWrite "Removed output files from $outputPath\VMBuild_$global:buildId"

        Remove-Item $outputPath\md5\VMBuild_$global:buildId -recurse -Force
        LogWrite "Removed output files from $outputPath\md5\VMBuild_$global:buildId"

    } else {
        LogWrite "Skipping remove output files from $outputPath\md5\VMBuild_$global:buildId"
    }
}

function Check-RestartEnableHyperV() {
    If ($HyperVEnabled -eq 0) {
        LogWrite "HyperV is not enabled. Restarting in 10s to enable..."
        Start-Sleep -s 10
        Create-RestartRegistryEntry
        Save-HyperVStatus 1
        Invoke-Expression "bcdedit /set hypervisorlaunchtype auto"
        Restart-Computer -Force
        Exit
    }
}

function Check-RestartDisableHyperV() {
    If ($HyperVEnabled -eq 1) {
        Create-RestartRegistryEntry
        LogWrite "HyperV is enabled. Restarting in 10s to disable..."
        Start-Sleep -s 10
        Save-HyperVStatus 0
        Invoke-Expression "bcdedit /set hypervisorlaunchtype off"
        Restart-Computer -Force
        Exit
    }
}

function Restart-System(){
    Create-RestartRegistryEntry
    LogWrite "Restarting in 10s..."
    Start-Sleep -s 10    
    Restart-Computer -Force
    Exit
}

function Clear-Temp () {
    try {
        $tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Documents and Settings\*\Local Settings\temp\*", "C:\Users\*\Appdata\Local\Temp\*")
        Remove-Item $tempfolders -force -recurse -ErrorAction SilentlyContinue | Out-Null
    }
    catch {

    }
}

function Save-HyperVStatus($isenabled){
    @{hypervenabled=$isenabled;} | ConvertTo-Json | Out-File "$global:Path\vmgen.cfg"
}

function Create-RestartRegistryEntry {
    $RegistryKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    $RegistryEntry = "Continuevmgen"
    $ScriptPath = $PSCommandPath

    LogWrite "Restart Registry Entry Does Not Exist - Creating It"

    IF(!(Test-Path $RegistryKey)) {
        New-Item -Path $RegistryKey -Force | Out-Null
    }

    Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File $($ScriptPath) -Build -Continue"
}

function Load-VMConfig {
    $strFileName="$global:Path\vmgen.cfg"

    If (Test-Path $strFileName){
        $config = (Get-Content $strFileName -Raw) | ConvertFrom-Json
        $global:HyperVEnabled = $config.hypervenabled
    } Else {
        $global:HyperVEnabled = 0
    }
}

function Load-VMProjectConfig {
    $global:Config = (Get-Content "$global:Path\vmgen.json" -Raw) | ConvertFrom-Json
    $global:buildId = $global:Config.Build
}

function Start-BuildPackerTemplates {

    $startTime = Get-Date
    LogWrite "Generating packer templates..."

    Invoke-Expression "$global:Path\BuildTemplates.ps1"
    LogWrite "Packer Templates generated."

    Create-LockFile $global:Config.VMS

    if ($Build -eq $False) {
        Get-Content "$global:Path\vmgen.json.lock" -Raw
    }
}

function Start-GenerationProcess {

    LogWrite "vmgen process started."

    LogWrite "Build ID: $global:buildId"

    $lock = (Get-Content "$global:Path\vmgen.json.lock" -Raw) | ConvertFrom-Json

    $lock |
    ForEach-Object {

        $item = $_

        If ($_.Generated -eq $False -and $_.Retried -eq $False) {                        

            $software = $_.Software
            $windows = $_.Windows
            $browser = $_.Browser
            $os = $_.OS            

            if ($item.Failed -eq $True -and $item.Retried -eq $False) {                    
                $item.Retried = $True
                LogWrite "Retrying $software $windows $browser"
            }

            $item.Start = Get-Date -Format G

            If ($os -eq "Windows") {
                If ($software -eq "HyperV" -or $software -eq "VPC") { Check-RestartEnableHyperV } Else { Check-RestartDisableHyperV }
            }

            try {

                If ($OnlyUpload -eq $False) {
                    switch ($_.OS)
                    {
                        "Windows" {
                            Generate-Windows $software $windows $browser $os
                            Export $software $windows $browser $os
                            Compress $software $browser $windows $os

                        }
                        "Mac"     {
                            Generate-Mac $software $windows $browser $os
                            Compress $software $browser $windows $os
                        }
                    }

                    $item.Generated = $True
                    LogWrite "$software $windows $browser succesfully created."
                }

                Upload
            }
            catch
            {
                LogWrite "Error: $_"
                $item.Failed = $True
                if ($item.Retried -eq $False) {                                       
                    LogWrite "Order retry for $software $windows $browser. Force restart before initiating process." 
                    $lock | ConvertTo-Json | Out-File "$global:Path\vmgen.json.lock"                   
                    Restart-System
                }                                                                                
            }

            $item.End = Get-Date -Format G
        }

        $lock | ConvertTo-Json | Out-File "$global:Path\vmgen.json.lock"
    }

    LogWrite "Process finished."

    Clear-Temp
}

function Generate-SofwareListJson () {
    Invoke-Expression "..\bin\VMSGen\VMSGen $global:Path\vmgen.json"
    LogWrite "Software List JSON generated in $($global:Config.OutputPath) folder."
}

function Send-NotificationEmail () {
    
    $smtp = $global:Config.Mail.SMTP
    $from = $global:Config.Mail.From
    $to = $global:Config.Mail.To
    $user = $global:Config.Mail.user
    $password = $global:Config.Mail.Password

    If ($password -eq "") {
        LogWrite "Cannot send email notification. Password not provided."
        return
    }

    $error = 0;
    $total = 0;

    $lock = (Get-Content "$global:Path\vmgen.json.lock" -Raw) | ConvertFrom-Json

    $list = ($lock | ForEach-Object{
        $total++
        If ($_.Failed -eq $True) {
            $status = "<span style='color:#c00'>Failed</span>"
            $error++
        } Else {
            $status = "<span style='color:#0c0'>Success</span>"
        }

    "`t<tr><td>$($_.OS)</td><td>$($_.Windows)</td><td>$($_.Software)</td><td>$($_.Browser)</td><td>$status</td></tr>"

    }) -join "`r`n"
    $finishTime = Get-Date -Format G
    $log = Get-Content "$LogFile" | ForEach-Object{  "$_<br>"}

    $template = Get-Content "$global:Path\template-parts\email-template.html" -Raw

    $body = $ExecutionContext.InvokeCommand.ExpandString($template)

    If ($error -gt 0 -And $error -eq $total) {
        $subjectstatus = "failed"
    } ElseIf ($error -gt 0) {
        $subjectstatus = "partially succeeded"
    } Else {
        $subjectstatus = "succeeded"
    }

    $subject = "vmgen Build $global:buildId $subjectstatus"

    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)

    $outputPath = $global:Config.OutputPath
    $vmsFile = "$outputPath\notification\vms.json"

    Send-mailmessage -to $to -from $from -subject $subject -credential $mycreds -useSSL -body $body -BodyAsHtml -Attachments $Logfile,$vmsFile -smtpServer $smtp

    LogWrite "Email sended to $to with '$subjectstatus' status"
}

function Prepare-SofwareListJsonToBeNotified () {
    $outputPath = $global:Config.OutputPath

    if (-Not (Test-Path $outputPath\notification)) {
            New-Item -ItemType Directory -Force -Path $outputPath\notification
        }

    if(Get-Member -inputobject $global:Config -name "OsRenaming" -Membertype Properties){
        $osRenames = $global:Config.OsRenaming.PSObject.Properties
        
        $vmsOutputList = (Get-Content "$outputPath\vms.json" -Raw) | ConvertFrom-Json

        foreach ($_ in $osRenames) {            
            foreach ($software in $vmsOutputList.softwareList) {
                foreach ($vms in $software.vms) {
                    if($vms.osVersion -eq $_.Name){
                        $vms.osVersion = $_.Value
                    }
                }
            }
        }        
        $vmsOutputList | ConvertTo-Json -depth 100 | Out-File "$outputPath\notification\vms.json"

    } else {
        Copy-Item $outputPath\vms.json $outputPath\notification
    } 
}

function Download-ISOs () {
    $url = $global:Config.AzureStorage.Url
    $key = $global:Config.AzureStorage.Key
    $start_time = Get-Date

    & ..\bin\AzCopy\AzCopy.exe /Source:$url/iso /Dest:iso /SourceKey:$key /Y /S
}

function Update-Mac() {
    $lock = (Get-Content "$global:Path\vmgen.json.lock" -Raw) | ConvertFrom-Json
    $MacImages = $lock | where { $_.OS -eq "Mac"} | Measure-Object
    if($MacImages.Count -gt 0){
        LogWrite "Mac images in the generation list. Updating files in the Mac machine..."

        $networkPath = $global:Config.Mac.NetworkPath
        $SSHUser = $global:Config.Mac.SSH_User
        $SSHPassword = $global:Config.Mac.SSH_Password

        If (!(Test-Path M:))
        {
            Invoke-Expression "net use M: $networkPath /USER:$SSHUser $SSHPassword"
            LogWrite "Drive M mapped to $networkPath"
        }   

        ROBOCOPY ..\scripts M:\scripts /MIR /R:5 /W:10 /xo /fft
    }
}

If ($Continue -eq $False -and (Test-Path $LogFile)) {
    Clear-Content $Logfile
}

Load-VMProjectConfig
Load-VMConfig

If ($Download -eq $True) {
    Download-ISOs
}

if($Continue -eq $False ){    
    Start-BuildPackerTemplates
    Update-Mac
}

If ($Build -eq $True) {
    Start-GenerationProcess
}

If ($GenerateJSON -eq $True -or $Build -eq $True) {
    Generate-SofwareListJson
    Prepare-SofwareListJsonToBeNotified
    Send-NotificationEmail
    Remove-OutputFiles
}