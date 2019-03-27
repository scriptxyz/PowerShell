Add-PSSnapIn ShareFile
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

$config = "C:\temp\sflogin.sfps"

if (![System.IO.File]::Exists($config)) {
    New-sfclient -Name "C:\temp\sflogin.sfps"
}

Function DeleteUsers {
    Param ([Parameter(HelpMessage = "Hi Test")] [string]$UserType = "employee")
    $client = Get-SfClient -Name "c:\temp\sflogin.sfps"

    $sfUserObjects = Import-Csv ("C:\temp\" + $UserType + ".csv")
    $count = 0

    foreach ($sfUser in $sfUserObjects) {

        Write-Host deleting $sfUser.Email
	#delete users files without re-assign
        Send-SfRequest -Client $client -Method Delete -Entity Users -Id $sfUser.UserId -Parameters @{"completely" = "true"}
	#delte users files and re-assign to someone
        #Send-SfRequest -Client $client -Method Delete -Entity Users -Id $sfUser.UserId -Parameters @{"itemsReassignTo" = "id of user"}

        $count = $count + 1
    }
    write-host "$count user accounts were deleted"

}

Write-host "Deleting disabled users in employee..."
write-host ""
DeleteUsers -UserType "employee";
write-host ""
write-host ""
Write-host "Deleting disabled users in client..."
write-host ""
DeleteUsers -UserType "client";