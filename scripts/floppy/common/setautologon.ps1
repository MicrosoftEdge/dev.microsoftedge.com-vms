$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String  
Set-ItemProperty $RegPath "DefaultPassword" -Value "Passw0rd!" -type String
Set-ItemProperty $RegPath "AutoAdminLogonCount" -Value 20 -type DWord