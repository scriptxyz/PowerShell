Function RegWrite ($regPath, $regName, $regValue, $regType)
{
    If (!(Test-Path $regPath))
    {
        New-Item -Path $regPath -force
    }
    New-ItemProperty $RegPath -Name $regName -Value $regValue -PropertyType $regType -force
}
#—————————-
# Disable offloads globally
#—————————-
RegWrite "HKLM:\System\CurrentControlSet\Services\TCPIP\Parameters\DisableTaskOffload" 1 DWord
#—————————-
# Disable all IPv6 in registry
#—————————-
RegWrite "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters" "DisabledComponents" 0x000000FF Dword
#—————————-
# Disable all offloads for VMXNET3 adapters
#—————————-
Get-ChildItem ‘HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}’ -rec -ea SilentlyContinue | foreach {
   $CurrentKey = (Get-ItemProperty -Path $_.PsPath)
   If ($CurrentKey -match "vmxnet3 Ethernet Adapter")
   {
    $StrKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\" + $CurrentKey.PSPath.Substring($CurrentKey.PSPath.Length – 4, 4)
    RegWrite $StrKeyPath "*IPChecksumOffloadIPv4" 0 String
    RegWrite $StrKeyPath "*TCPChecksumOffloadIPv4" 0 String
    RegWrite $StrKeyPath "*UDPChecksumOffloadIPv4" 0 String
    RegWrite $StrKeyPath "*LsoV1IPv4" 0 String
    RegWrite $StrKeyPath "*LsoV2IPv4" 0 String
    RegWrite $StrKeyPath "OffloadIPOptions" 0 String
    RegWrite $StrKeyPath "OffloadTcpOptions" 0 String
    
    }
  }