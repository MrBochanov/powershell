Param()

$DCS = Get-ADGroupMember 'Domain Controllers'
$ITOG = @()

foreach ($DC in $DCS)
{

 $ITOG += Get-DhcpServerv4Scope -ComputerName $DC.name | Get-DhcpServerv4Lease -ComputerName $DC.name #| +=$ITOG # | Export-Csv "d:\Clients2.csv" -Encoding UTF8 -Force -NoTypeInformation

}

$ITOG |  Export-Csv "d:\AllDHCPServerLeases.csv" -Encoding UTF8 -Force -NoTypeInformation
