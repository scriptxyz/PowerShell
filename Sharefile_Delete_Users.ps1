Add-PSSnapIn ShareFile
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

$config = "C:\temp\sflogin.sfps"

if (![System.IO.File]::Exists($config)) {
    New-sfclient -Name "C:\temp\sflogin.sfps"
}

Function DeleteUsers {
    Param ([Parameter(HelpMessage = "Hi Keith")] [string]$UserType = "employee")
    $client = Get-SfClient -Name "c:\temp\sflogin.sfps"

    $sfUserObjects = Import-Csv ("C:\temp\" + $UserType + ".csv")
    $count = 0

    foreach ($sfUser in $sfUserObjects) {
        Send-SfRequest -Client $client -Method Delete -Entity Users -Id $sfUser.UserId -Parameters @{"completely" = "true"}
        $count = $count + 1
    }
    write-host "$count user accounts were deleted"

}

Write-host "Deleting disabled users in employee..."
write-host ""
write-host ""
DeleteUsers -UserType "employee";
Write-host "Deleting disabled users in client..."
write-host ""
write-host ""
DeleteUsers -UserType "client";