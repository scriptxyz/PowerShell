asnp citrix*
$DDC = "aalxndsyd101"
$VDIList = get-brokermachine -AdminAddress $DDC -MaxRecordCount 1000 |Select-Object DNSName, IPAddress

ForEach ($VDI in $VDIList) {

    if ($VDI.DNSName -like "APRP*" ) {

        $Ping = New-Object System.Net.NetworkInformation.Ping
        $PingResponse = $Ping.Send($VDI.DNSName)

        If ($PingResponse.Status -eq "TimedOut") {
            Write-host "$VDI.DNSName timeout"
        }
        else {
	        $setting =Invoke-Command -computername $VDI.DNSName -scriptblock { Get-ItemProperty -path "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -name PagingFiles}
            write-host $VDI.DNSName "-" $setting.PagingFiles
        }
    }
}