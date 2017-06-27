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


param(
    [string] $OriginalName, 
    [string] $NewName
)

if([string]::IsNullOrEmpty($OriginalName) -or [string]::IsNullOrEmpty($NewName)){
    Write-Output "The script requires 2 parameters, OriginalName and NewName." 
    Write-Output "Example: rename from win10_preview to Windows 10 (x64) Build 34567 ->.\vmsrename.ps1 `"win10_preview`"  `"Windows 10 (x64) Build 34567`" "
    exit 
} 

$file = (Get-Content "vms.json" -Raw) | ConvertFrom-Json

$file.softwareList |
    ForEach-Object {
        $_.vms |
        ForEach-Object {
            if($_.osVersion -eq $OriginalName){
                $_.osVersion = $NewName
            }
        }
    }

$file | ConvertTo-Json -depth 100 | Out-File "vms_renamed.json"