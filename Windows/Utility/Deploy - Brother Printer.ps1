#Brother MFC-J5740DW Printer
$strFolderPath = "$env:TEMP\DIR"
$strDownloadURL = "https://download.brother.com/welcome/dlf106282/Y21A_C1-hostm-K1.EXE"

Invoke-WebRequest -Uri "$strDownloadURL" -OutFile "$strFolderPath\Y21A_C1-hostm-K1.EXE"
Start-Process "$strFolderPath\Y21A_C1-hostm-K1.EXE" -WorkingDirectory "$strFolderPath" -Wait
Start-Process "$strFolderPath\gdi\dpinstx64.exe" -WorkingDirectory "$strFolderPath" -ArgumentList "/Q /F /SE /SW" -Wait

<#
PS $($env:SYSTEMDRIVE)\Users\TEST\Downloads\gdi> .\dpinstx64.exe /?
$($env:SYSTEMDRIVE)\Users\TEST\Downloads\gdi\dpinstx64.exe: installs and uninstalls driver packages.
By default, the tool searches the current directory and tries to install all driver packages found.

Usage: $($env:SYSTEMDRIVE)\Users\TEST\Downloads\gdi\dpinstx64.exe [/U INF-file][/S | /Q][/LM][/P][/F][/SH][/SA][/A][/PATH Path][/EL][/L LanguageID][/C][/D][/LogTitle Title][/SW][/? | /h | /help]

  /U INF-file    Uninstall a driver package (INF-file).
  /S | /Q        Silent (Quiet) mode. Suppresses the Device Installation Wizard and any dialogs popped-up by the operating system.
  /LM    Legacy mode. Accepts unsigned driver packages and packages with missing files. These packages won't install on the latest version of Windows.
  /P     Prompt if the driver package to be installed is not better than the current one.
  /F     Force install if the driver package is not better than the current one.
  /SH    Scans hardware for matching devices and only copies and installs those drivers for which a device is present. Only valid for Plug and Play drivers.
  /SA    Suppress the Add/Remove Programs entry normally created for each driver package.
  /A     Install all or none.
  /PATH Path     Search for driver packages under the given path.
  /EL    Enables all languages not explicitly listed in the XML file.
  /L LanguageID          Tries to use the given language in all UI. Useful for localization tests.
  /SE    Suppress the EULA.
  /C     Dump logging output to attached Console (Windows XP and above).
  /D     Delete driver binaries on uninstall.
  /SW    Suppresses the Device Installation Wizard, the operating system might still pop-up user dialogs.
  /? | /h | /help        Shows this help.
#>