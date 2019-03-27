#version 1.2
$machinename = hostname
if ($machinename -like "APRP*") {
    Write-Host 'Enable System Automatic Managed Pagefile .'
    $setpagefile = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges;
    $setpagefile.AutomaticManagedPagefile = $False;
    #$setpagefile.AutomaticManagedPagefile = $True
    $pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name like '%pagefile.sys'";
    $pagefile.InitialSize = 1024;
    $pagefile.MaximumSize = 6144;
    $pagefile.Put();
} 