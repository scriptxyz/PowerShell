Add-PSSnapIn ShareFile
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

$config = "C:\temp\sflogin.sfps"

if (![System.IO.File]::Exists($config)) {
    New-sfclient -Name "C:\temp\sflogin.sfps"
}

$txt = Read-Host -Prompt 'Please enter txt file path'
$emails = @()

if (![System.IO.File]::Exists($txt)) {
    write-host "txt files doesn't exist, now quit"
    exit
}
else {

    $Emails = get-content -path $txt

    $sflogin = Get-SfClient -Name "c:\temp\sflogin.sfps"
    $count = 0

    foreach ($email in $Emails) {
        $user = Send-SFRequest –Client $sfLogin –Method GET –Entity "Users?emailaddress=$email" -Expand Security
        $id = $user.Id
        Send-SfRequest -Client $sfLogin -Method PATCH -Entity "Users($id)" -BodyText '{"Security": {"IsDisabled" : "True"}}'
        write-host "Disable Account of " $user.FullName
        $count = $count + 1
    }

    write-host ""
    write-host ""
    write-host ""
    write-host "disabled $count Accounts"
}