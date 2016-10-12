REM  --------------------------------------------------------------
REM
REM   dev.microsoftedge.com -VMs
REM   Copyright(c) Microsoft Corporation. All rights reserved.
REM
REM   MIT License
REM
REM   Permission is hereby granted, free of charge, to any person obtaining
REM   a copy of this software and associated documentation files(the ""Software""),
REM   to deal in the Software without restriction, including without limitation the rights
REM   to use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
REM   of the Software, and to permit persons to whom the Software is furnished to do so,
REM   subject to the following conditions :
REM
REM   The above copyright notice and this permission notice shall be included
REM   in all copies or substantial portions of the Software.
REM
REM   THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
REM   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
REM   FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS
REM   OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
REM   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
REM   OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
REM
REM  --------------------------------------------------------------

net stop wuauserv

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v EnableFeaturedSoftware /t REG_DWORD /d 1 /f

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v IncludeRecommendedUpdates /t REG_DWORD /d 1 /f

echo Set ServiceManager = CreateObject("Microsoft.Update.ServiceManager") > A:\temp.vbs
echo Set NewUpdateService = ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") >> A:\temp.vbs

cscript A:\temp.vbs

net start wuauserv