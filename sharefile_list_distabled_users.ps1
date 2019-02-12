Add-PSSnapIn ShareFile
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

Function FindDisabledUsers{
Param ( [string]$UserType="employee")
      $client = Get-SfClient -Name "c:\temp\sflogin.sfps"
      $entity = "";
      switch ($UserType.ToLower()){
        "employee"{
            $entity = 'Accounts/Employees';
        } 
        "client" {
          $entity = 'Accounts/Clients';
        }
      }
      #Pull all of the Account Employees or Clients
      $sfUsers = Send-SfRequest -Client $client -Entity $entity

      $fileOutput = @()
      $user_count = 0
      $disableduser = 0
      #Loop through each of the Employees or Clients returned from inital call
      foreach($sfUserId in $sfUsers){
            #Get full user information including security 
            $sfUser = Send-SfRequest -Client $client -Entity Users -Id $sfUserId.Id -Expand Security
            #Output to Console Emails of disabled users
            $user_count = $user_count + 1
            #check to see if security parameter IsDisabled is true
            switch ($sfUser.Security.IsDisabled ) {
                "True" {
                    $fileOutput += New-Object PSObject -Property @{'UserId'=$sfUserId.Id;'FullName'=$sfUser.FullName;'Email'=$sfUser.Email}
                    write-host $sfUser.Email
                    $disableduser = $disableduser + 1
                }
            }
      }

    #Output CSV file with all disabled user information
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