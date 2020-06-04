Param()

$key = (supersecrepkey)
$password = Get-Content C:\Var\Scripts\password.txt | ConvertTo-SecureString -Key $key
$creds = New-Object System.Management.Automation.PSCredential "DOMAIN\sa-newmailbox",$password


$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://mail01.bb.local/PowerShell -Authentication Kerberos -Credential $creds
Import-PSSession $session -AllowClobber

$When = ((Get-Date).AddHours(-3)).Date
$LastUsers = Get-ADUser -Filter {whenCreated -ge $When} -SearchBase "OU=DOMAIN,DC=bb,DC=local"  -Properties whenCreated, mail

$LastUsers = $LastUsers | Where-Object {$_.mail -ne $null}

$encoding = [System.Text.Encoding]::UTF8
$body = Get-Content -Path "\\fs\Public\!_Pamyatka\body.txt" | Out-String


foreach ($LastUser in $LastUsers) {

Send-MailMessage -From "it@mail.ru" -To $LastUser.mail -Subject "Памятка от ИТ отдела, просьба изучить!" -Body $body   -SmtpServer "mail.domain.ru" -Attachments "\\fs\Public\!_Pamyatka\!Памятка от IT.docx" -Encoding $encoding


#Write-Host $LastUser.mail
}
