#Version 1.1
Write-Host "Stop SCCM agent"
Stop-service -name "CcmExec"
write-host "delete SCCM client certificates"
cd hklm:
Remove-Item -Path  HKLM\software\Microsoft\Systemcertificates\SMS\Certificate -Recurse -Force -Confirm:$false
cd C:\Windows\ccmsetup\
CCMSetup.exe RESETKEYINFORMATION=TRUE
write-Host "delete sccm cache and logs"
Remove-item -Path c:\windows\ccmcache -Recurse -Force -Confirm:$false
Remove-item -Path c:\windows\ccm\logs -Recurse -Force -Confirm:$false
Remove-item -Path  c:\windows\smscfg.ini  -Recurse -Force -Confirm:$false
write-Host "Delete the Hardware Inventory cache"
$IAID = Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus | Where-Object {$_.InventoryActionID -eq "{00000000-0000-0000-0000-000000000001}"}
$IAID | Remove-WmiObject -Verbose
write-Host "disable sccm agent"
Set-Service -name "CcmExec" -StartupType Disabled