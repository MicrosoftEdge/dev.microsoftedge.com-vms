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


function ReplaceVariableContent ($file, $vmname) {
    # packer doesnot replace vm_name variable
    (gc ".\template-output\$file.json").replace('{{ user `vmname` }}', $vmname) | sc ".\template-output\$file.json"

}

$template = "MSEdge-Win10_Preview"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\user.json,.\template-parts\urls_win10_previewx64.json,.\template-parts\win10_previewx64.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win10_previewx64.json,.\template-parts\provisioner_common.json,.\template-parts\pp-vagrant.json" -o:.\template-output\$template.json
Write-Verbose "$template.json created."

$template = "MSEdge-Win10"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\user.json,.\template-parts\urls_win10x64.json,.\template-parts\win10x64.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win10.json,.\template-parts\provisioner_common.json,.\template-parts\pp-vagrant.json" -o:.\template-output\$template.json
Write-Verbose "$template.json created."

$template = "IE11-Win81"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\user.json,.\template-parts\urls_win81x64.json,.\template-parts\win81x64.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win81.json,.\template-parts\provisioner_common.json,.\template-parts\pp-vagrant.json" -o:.\template-output\$template.json
Write-Verbose "$template.json created."

$template = "IE11-Win7"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\variables_win7_ie11.json,.\template-parts\user.json,.\template-parts\urls_win7x86.json,.\template-parts\win7x86.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win7.json,.\template-parts\pp-vagrant.json,.\template-parts\provisioner_commonx86.json" -o:.\template-output\$template.json
ReplaceVariableContent $template "IE11 - Win7"
Write-Verbose "$template.json created."

$template = "IE10-Win7"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\variables_win7_ie10.json,.\template-parts\user.json,.\template-parts\urls_win7x86.json,.\template-parts\win7x86.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win7.json,.\template-parts\pp-vagrant.json,.\template-parts\provisioner_commonx86.json" -o:.\template-output\$template.json
ReplaceVariableContent $template "IE10 - Win7"
Write-Verbose "$template.json created."

$template = "IE9-Win7"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\variables_win7_ie9.json,.\template-parts\user.json,.\template-parts\urls_win7x86.json,.\template-parts\win7x86.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win7.json,.\template-parts\pp-vagrant.json,.\template-parts\provisioner_commonx86.json" -o:.\template-output\$template.json
ReplaceVariableContent $template "IE9 - Win7"
Write-Verbose "$template.json created."

$template = "IE8-Win7"
..\bin\PackerMerge\PackerMerge -i:".\template-parts\variables_win7_ie8.json,.\template-parts\user.json,.\template-parts\urls_win7x86.json,.\template-parts\win7x86.json,.\template-parts\floppy_files_common.json,.\template-parts\floppy_files_win7.json,.\template-parts\pp-vagrant.json,.\template-parts\provisioner_commonx86.json" -o:.\template-output\$template.json
ReplaceVariableContent $template "IE8 - Win7"
Write-Verbose "$template.json created."