$Users = Get-ADUser -Filter * -SearchBase "OU=Service Accounts and Groups,DC=bb,DC=local" -Properties name,accountExpires | where {$_.accountExpires -ne "9223372036854775807"}
$3DaysLeft = ((Get-Date).AddDays(+4)).Date
$2DaysLeft = ((Get-Date).AddDays(+3)).Date
$1DaysLeft = ((Get-Date).AddDays(+2)).Date

$MASSIV = @() ; $body = @()

foreach ($User in $Users) { $User.AccEX = ([DateTime]$User.accountExpires).AddYears(1600).ToLocalTime()}

foreach ($User in $Users) {


    if ($User.AccEX -eq $3DaysLeft) {$MASSIV+= $User.Name +" will Expire in 3 days"}
    if ($User.AccEX -eq $2DaysLeft) {$MASSIV+= $User.Name +" will Expire in 2 days"}
    if ($User.AccEX -eq $1DaysLeft) {$MASSIV+= $User.Name +" will Expire in 1 days"}

    }


if ($MASSIV[0] -eq $null ) {Write-Host "nothing to do"}
else {

#$MASSIV+= "Remind You:";$MASSIV+=""

#$MASSIV+="";$MASSIV+= "Do something or just forget about it"

#$body = $MASSIV| Out-String

$body+= "Remind You:" ;$body+=""
$body+= $MASSIV
$body+="";$body+= "Do something or just forget about it"

$body = $body | Out-String


Send-MailMessage -From "it@mail.ru" -To "it@mail.ru" -Subject "Expired Accounts Reminder" -Body $body   -SmtpServer "mail.domain.ru"  #-Encoding $encoding

}
