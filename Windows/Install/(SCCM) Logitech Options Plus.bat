@echo off
cd "\\10.60.1.22\Sources\Applications\Logitech\Logitech_Options_Plus\1.85\"
mkdir "C:\TEST" 2>nul #PRIVATE
start /wait "" "logioptionsplus_installer_offline.exe" /quiet /flow No /log "C:\TEST\optionsplus.log" #PRIVATE
exit /b %ERRORLEVEL%