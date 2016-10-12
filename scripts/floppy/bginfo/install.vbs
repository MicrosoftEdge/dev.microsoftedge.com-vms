'--------------------------------------------------------------
'
' dev.microsoftedge.com -VMs
' Copyright(c) Microsoft Corporation. All rights reserved.
'
' MIT License
'
' Permission is hereby granted, free of charge, to any person obtaining
' a copy of this software and associated documentation files(the ""Software""),
' to deal in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
' of the Software, and to permit persons to whom the Software is furnished to do so,
' subject to the following conditions :
'
' The above copyright notice and this permission notice shall be included
' in all copies or substantial portions of the Software.
'
' THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
' INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
' FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS
' OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
' WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
' OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
'
'--------------------------------------------------------------
'========================================================================================
' BGinfo Installation Script
'========================================================================================
'
' Script Details:
' --------------
' This script copies the BGinfo files to the C:\bginfo folder and sets the run registry key
'========================================================================================
Option Explicit

Dim objShell, objFSO, intErrorCode

Set objShell = CreateObject("WScript.Shell")
Set objFSO = createobject("scripting.filesystemobject")

On Error Resume Next

If not objFSO.FolderExists("C:\BGinfo") Then
 objFSO.CreateFolder("C:\BGinfo")
End If

intErrorCode = intErrorCode + objFSO.CopyFile("A:\Bginfo.exe", "C:\BGinfo\")
intErrorCode = intErrorCode + objFSO.CopyFile("A:\bgconfig.bgi", "C:\BGinfo\")
intErrorCode = intErrorCode + objFSO.CopyFile("A:\background.jpg", "C:\BGinfo\")

intErrorCode = intErrorCode + objshell.RegWrite("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\bginfo", "C:\BGinfo\Bginfo.exe /accepteula /ic:\bginfo\bgconfig.bgi /timer:0", "REG_SZ")

objShell.Run "C:\bginfo\Bginfo.exe /accepteula /ic:\bginfo\bgconfig.bgi /timer:0"

Set objShell = Nothing
Set objFSO = Nothing

WScript.Quit(intErrorCode)
