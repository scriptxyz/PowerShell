#Version 1.2
Write-Host 'Clearing CleanMgr.exe automation settings.'
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*' -Name StateFlags0001 -ErrorAction SilentlyContinue | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

Write-Host 'Enabling Update Cleanup. This is done automatically in Windows 10 via a scheduled task.'

New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files' -Name StateFlags0001 -Value 2 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files' -Name StateFlags0001 -Value 2 -PropertyType DWord

Write-Host 'Stopping Windows Update Service'
Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue

$IEFolders = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$IECookies = $IEFolders.Cookies
$IECache = $IEFolders.Cache
$IEHistory = $IEFolders.History
$Profile = "%UserProfile%\AppData\Local\Temp\"
$Paths = "C:\Windows\Temp\*",
         "C:\windows\SoftwareDistribution\Download\*",
         "$IECookies\*",
         "$IECache\*",
         "$IEHistory\*",
         "$env:LOCALAPPDATA\Temp\*"

Write-Host Deleting all possible content from temporary folders. -ForegroundColor Green
foreach ($path in $paths)
{
    del -path $path -Recurse -Force -ErrorAction SilentlyContinue
}


if ((Get-CimInstance Win32_OperatingSystem).version -gt 6.2) {
    Write-Host 'Reset Windows base image'
    DISM.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
}

Write-Host Clearing ARP Cache. -ForegroundColor Green
netsh interface ip delete arpcache

Write-Host Flushing DNS Cache. -ForegroundColor Green
ipconfig /flushdns

Write-Host Deleting all possible Event Log entries. -ForegroundColor Green
wevtutil.exe el | foreach-object {wevtutil.exe cl "$_"} 2>&1 | Out-Null

Write-Host Clearing out the Recycle Bin -ForegroundColor Green
Get-ChildItem "C:\`$Recycle.Bin\" -Force | del -Recurse -ErrorAction SilentlyContinue

$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" 
$history = (Get-Item -Path $path).Property 
foreach($item in $history) 
{ 
   if($item -ne "MRUList") 
   { 
     Remove-ItemProperty -Path $path -Name $item -ErrorAction SilentlyContinue 
   } 
} 
  
Write-Host "Remove RUN box history successfully." 

Write-Host 'Starting CleanMgr.exe...'
Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -WindowStyle Hidden -Wait

Write-Host 'Waiting for CleanMgr and DismHost processes. Second wait neccesary as CleanMgr.exe spins off separate processes.'
Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process


$temporaryIEDir = "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*"
$cachesDir = "C:\Users\*\AppData\Local\Microsoft\Windows\Caches"
Write-Host 'Delete Temporary Internet Files for all users'
Get-ChildItem $temporaryIEDir, $cachesDir -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } | remove-item -force -recurse -ErrorAction SilentlyContinue

Write-Host 'Starting Windows Update Service'
Get-Service -Name wuauserv | Start-Service

$UpdateCleanupSuccessful = $false
if (Test-Path $env:SystemRoot\Logs\CBS\DeepClean.log) {
    $UpdateCleanupSuccessful = Select-String -Path $env:SystemRoot\Logs\CBS\DeepClean.log -Pattern 'Total size of superseded packages:' -Quiet
}

if ($UpdateCleanupSuccessful) {
    Write-Host 'Rebooting to complete CleanMgr.exe Update Cleanup....'
    SHUTDOWN.EXE /r /f /t 0 /c 'Rebooting to complete CleanMgr.exe Update Cleanup....'
}
else {
    Write-Host 'Disk cleanup completed, no reboot is needed.'
}