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

@echo off
setlocal EnableDelayedExpansion
set c=0
for /f "tokens=2 delims=:, " %%a in (' find ":" ^< "a:\build.cfg" ') do (
   set /a c+=1
   set val[!c!]=%%~a
)
for /L %%b in (1,1,!c!) do echo %%b !val[%%b]!

IF %val[1]%==IE7 (
  echo %val[2]% > a:\build.txt
  echo %val[1]% > a:\ie.txt
  echo %val[3]% > a:\software.txt
)

IF [%1]==[FIRST] GOTO POWERSHELL
IF [%1]==[SECOND] GOTO END
IF %val[3]%==HyperV GOTO HYPERV
GOTO POWERSHELL

:HYPERV
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\0001" /v Entry1 /t REG_SZ /d "cmd.exe /c a:\preprovisioner.cmd FIRST" /f
E:\support\x86\setup /quiet
IF ERRORLEVEL 6001 shutdown /r /f /t 0 /c "server reboot" /d p:1:1
GOTO END

:POWERSHELL
IF NOT %val[1]%==IE7 GOTO END
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\0001" /v Entry1 /t REG_SZ /d "cmd.exe /c a:\preprovisioner.cmd SECOND" /f
bitsadmin /transfer myDownloadJob /download /priority normal http://download.microsoft.com/download/A/7/5/A75BC017-63CE-47D6-8FA4-AFB5C21BAC54/Windows6.0-KB968930-x86.msu c:\windows\temp\Windows6.0-KB968930-x86.msu
wusa.exe c:\windows\temp\Windows6.0-KB968930-x86.msu /quiet

:END
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File A:\preprovisioner.ps1 -Wait

:NONE