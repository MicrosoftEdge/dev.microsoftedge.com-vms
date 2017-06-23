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
if not exist "C:\Windows\Temp\7z920.msi" (
    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://www.7-zip.org/a/7z920.msi', 'C:\Windows\Temp\7z920.msi')" <NUL
)
msiexec /qb /i C:\Windows\Temp\7z920.msi

if "%PACKER_BUILDER_TYPE%" equ "vmware-iso" goto :vmware
if "%PACKER_BUILDER_TYPE%" equ "virtualbox-iso" goto :virtualbox
if "%PACKER_BUILDER_TYPE%" equ "parallels-iso" goto :parallels
goto :done

:vmware
echo vmware
if exist "C:\Users\IEUser\windows.iso" (
    move /Y C:\Users\IEUser\windows.iso C:\Windows\Temp
)

echo vmware step1
if not exist "C:\Windows\Temp\windows.iso" (
    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://softwareupdate.vmware.com/cds/vmw-desktop/ws/11.1.2/2780323/windows/packages/tools-windows-9.9.3.exe.tar', 'C:\Windows\Temp\vmware-tools.exe.tar')" <NUL
    cmd /c ""C:\Program Files ^(x86^)\7-Zip\7z.exe" x C:\Windows\Temp\vmware-tools.exe.tar -oC:\Windows\Temp"
    FOR /r "C:\Windows\Temp" %%a in (tools-windows-*.exe) DO REN "%%~a" "tools-windows.exe"
    cmd /c C:\Windows\Temp\tools-windows
    move /Y "C:\Program Files ^(x86^)\VMware\tools-windows\windows.iso" C:\Windows\Temp
    rd /S /Q "C:\Program Files ^(x86^)\VMWare"
)

echo vmware step2
cmd /c ""C:\Program Files ^(x86^)\7-Zip\7z.exe" x "C:\Windows\Temp\windows.iso" -oC:\Windows\Temp\VMWare"
echo vmware step3
cmd /c C:\Windows\Temp\VMWare\setup.exe /S /v"/qn REBOOT=R\"

goto :done

:virtualbox

:: There needs to be Oracle CA (Certificate Authority) certificates installed in order
:: to prevent user intervention popups which will undermine a silent installation.
cmd /c "e: && cd cert && for %%i in (vbox*.cer) do VBoxCertUtil add-trusted-publisher %%i --root %%i"
:: cmd /c certutil -addstore -f "TrustedPublisher" A:\oracle-cert.cer

::move /Y C:\Users\IEUser\VBoxGuestAdditions.iso C:\Windows\Temp
::cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\VBoxGuestAdditions.iso -oC:\Windows\Temp\virtualbox"
cmd /c E:\VBoxWindowsAdditions.exe /S
goto :done

:parallels
if exist "C:\Users\IEUser\prl-tools-win.iso" (
	move /Y C:\Users\IEUser\prl-tools-win.iso C:\Windows\Temp
	cmd /C "C:\Program Files ^(x86^)\7-Zip\7z.exe" x C:\Windows\Temp\prl-tools-win.iso -oC:\Windows\Temp\parallels
	cmd /C C:\Windows\Temp\parallels\PTAgent.exe /install_silent
	rd /S /Q "c:\Windows\Temp\parallels"
)

:done
msiexec /qb /x C:\Windows\Temp\7z920.msi

SET ERRORLEVEL=0