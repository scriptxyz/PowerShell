Add-PSSnapIn ShareFile
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

$config = "C:\temp\sflogin.sfps"

if (![System.IO.File]::Exists($config)) {
    New-sfclient -Name "C:\temp\sflogin.sfps"
}

Function FindDisabledUsers {
    Param ( [string]$UserType = "employee")
    $client = Get-SfClient -Name "c:\temp\sflogin.sfps"
    $entity = "";
    switch ($UserType.ToLower()) {
        "employee" {
            $entity = 'Accounts/Employees';
        } 
        "client" {
            $entity = 'Accounts/Clients';
        }
    }

    $sfUsers = Send-SfRequest -Client $client -Entity $entity

    $fileOutput = @()
    $user_count = 0
    $disableduser = 0

    foreach ($sfUserId in $sfUsers) {
        $sfUser = Send-SfRequest -Client $client -Entity Users -Id $sfUserId.Id -Expand Security

        $user_count = $user_count + 1

        switch ($sfUser.Security.IsDisabled ) {
            "True" {
                $fileOutput += New-Object PSObject -Property @{'UserId' = $sfUserId.Id; 'FullName' = $sfUser.FullName; 'Email' = $sfUser.Email}
                write-host $sfUser.Email
                $disableduser = $disableduser + 1
            }
        }
    }

    $fileOutput | Export-Csv ("C:\temp\" + $UserType + ".csv") -Force -NoTypeInformation
    Write-Host $UserType + "$Total user number: " + $user_count
    Write-Host $UserType + "Disabled user number: " + $disableduser
}


write-host "Checking employee"
write-host ""
write-host ""

FindDisabledUsers -UserType "employee";

write-host "Checking clients"
FindDisabledUsers -UserType "client";