Add-PSSnapIn ShareFile
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

$config = "C:\temp\sflogin.sfps"

if (![System.IO.File]::Exists($config)) {
    New-sfclient -Name "C:\temp\sflogin.sfps"
}

$sfLogin = Get-sfclient –Name "c:\temp\sflogin.sfps"
$email = Read-Host -Prompt 'Please enter email address'
$user = Send-SFRequest –Client $sfLogin –Method GET –Entity Accounts/Employees |Where-Object {$_.email -eq $email}
write-host ""
write-host ""
write-host $user.name
write-host $user.id
write-host $user.email
