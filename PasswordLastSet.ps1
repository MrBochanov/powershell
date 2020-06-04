

$d = Get-Date "15/06/2020 06:00 AM"

$A = Get-ADGroupMember -Identity "VPN USERS" | Sort-Object  | foreach {Get-ADUser -Identity $_.distinguishedName  -Properties pwdLastSet} | select -Property Name, pwdLastSet

$A | foreach {  if ($_.pwdLastSet –lt $d.ToFileTimeUtc()) { $date = [datetime]::fromFileTime($_.pwdLastSet) ; Write-Host $_.Name, $date }} #не сменили

$A | foreach {  if ($_.pwdLastSet -ge $d.ToFileTimeUtc()) { $date = [datetime]::fromFileTime($_.pwdLastSet) ; Write-Host $_.Name, $date }} #сменили
