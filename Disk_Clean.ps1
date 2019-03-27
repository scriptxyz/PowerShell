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

Write-Host 'Cleanup SoftwareDistribution folder'
Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | remove-item -force -recurse -ErrorAction SilentlyContinue
Write-Host 'Cleanup Temp folder'
Get-ChildItem "C:\Windows\Temp\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | 
    Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } | 
    remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue

Write-Host 'Update native images'
$ngens = Get-ChildItem -Path $env:windir\Microsoft.Net -Filter ngen.exe -Recurse; foreach ($ngen in $ngens) {& "$($ngen.Directory)\$($ngen)" executeQueuedItems} 
 
Get-ChildItem $env:SystemRoot\Microsoft.net\NGen.exe -recurse | % { & $_ executeQueuedItems }

if ((Get-CimInstance Win32_OperatingSystem).version -gt 6.2) {
    Write-Host 'Reset Windows base image'
    DISM.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
}

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
} else {
    Write-Host 'Disk cleanup completed, no reboot is needed.'
}