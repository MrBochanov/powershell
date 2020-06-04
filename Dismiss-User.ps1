#account name
Param(
  [string]$samAccountName = "dmitrii.kirin"
)

## 0 Get ALL Needed Info about User ONCE
$ALLINFO = Get-ADUser -Identity $samAccountName -Properties cn, sAMAccountName, title, department, manager, description, telephoneNumber, mail, mobile, distinguishedName, SID | select -Property cn, sAMAccountName, title, department, manager, description, telephoneNumber, mail, mobile, distinguishedName, SID

## 1. Create folder for Dissmised User (PST, Info, etc.)

$accountOU = $ALLINFO.distinguishedName
$accountOU = $accountOU.Replace(",OU=DOMAIN,DC=bb,DC=local","") -replace '.*Users,OU=',''
$exportPSTPath = "\\fs\Dissmised\Backup User Folders\" + "!" + $accountOU + "\" + $samAccountName

New-Item -Path $exportPSTPath -ItemType Directory -ErrorAction SilentlyContinue

##2. Get-Account Information
# 2.1 Common info

#$info = Get-ADUser -Identity $samAccountName -Properties cn, sAMAccountName, title, department, manager, description, telephoneNumber, mail, mobile | select -Property cn, sAMAccountName, title, department, manager, description, telephoneNumber, mail, mobile
$info = $ALLINFO | select -Property cn, sAMAccountName, title, department, manager, description, telephoneNumber, mail, mobile

# 2.2 Add groups info
$groups = Get-ADPrincipalGroupMembership $samAccountName | select @{Name="Groups";Expression={$_.name}}
$groupstmp = $null
foreach ($group in $groups){$groupstmp = $groupstmp + $group.groups + "; "}
$info | Add-Member -NotePropertyName Groups -NotePropertyValue $groupstmp

# 2.3 Info to Dismissed folder
$info | Out-File $exportPSTPath\$samAccountName.txt

## 3. Generate a random password
Function GET-Temppassword()
{
    Param(
    [int]$length=20
    )
    $TempPassword = -join ((65..90) + (97..122) | Get-Random -Count $length | % {[char]$_})
    $TempPassword += Get-Random
    return $TempPassword
}
$pass = GET-Temppassword

## 4. Change account password
Set-ADAccountPassword -Identity $samAccountName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $pass -Force)

## 5. Hide from Address List
#Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://mail01.domain.local/PowerShell -Authentication Kerberos
Import-PSSession $session -AllowClobber
Set-Mailbox -identity $samAccountName -HiddenFromAddressListsEnabled $true

## 6. Copy $SID.vhdx
#$sid = get-aduser $samAccountName -properties * | % {$_.SID}
$sid = $ALLINFO.SID.Value
$vhdxFile = "\\fs\Profiles$\RDP\UVHD-" + $sid + ".vhdx"

if (Test-Path $vhdxFile)
    {
        Copy-Item $vhdxFile $exportPSTPath
    }
    else {Write-Host "Cant Find" $vhdxFile}


## 7. Change description + Remove Phone Number
#$description = get-aduser $samAccountName -properties * | % {$_.description}
$date = get-date -Format M-d-yyyy
$description += " (dismissed by "+$env:UserName+" at "+$date+")"
Set-ADUser $samAccountName -Replace @{description=$description}

Set-ADUser $samAccountName  -OfficePhone $null

## 8. Export PST to Dissmised Folder

New-MailboxExportRequest -Mailbox $samAccountName -FilePath $exportPSTPath\$samAccountName.pst -AsJob
$Check = Get-Mailbox -Identity $samAccountName
if (($Check.ArchiveDatabase -eq "BB-OA01") -or ($Check.ArchiveDatabase -eq "BB-OA02") )
{

Write-Host "есть архив"
New-MailboxExportRequest –Mailbox $samAccountName -IsArchive -FilePath $exportPSTPath\$samAccountName.archive.pst -AsJob
}

## 9. Remove account from all groups

#$accountgroups = Get-ADPrincipalGroupMembership $samAccountName | % {$_.name}
foreach ($g in $groups)
    {
        if ($g.Groups -match "Domain Users"){}

        else {Remove-ADGroupMember -Identity $g.Groups -Member $samAccountName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null  }#-WhatIf
    }

## 10. Move account to OU = DELETED + Disable Account

$TargetOU = "OU="+$accountOU+",OU=Deleted,OU=SANDBOX,DC=bb,DC=local"
Get-ADUser $samAccountName | Move-ADObject -TargetPath $TargetOU #-WhatIf

Disable-ADAccount $samAccountName

## 11. Send an E-mail to it@bigbox.ru
$subj = "User was dissmised!"
$from = $env:COMPUTERNAME + "@bb.local"
$to = "it@mail.ru"
$info | Add-Member -NotePropertyName Dissmised -NotePropertyValue $description
$body = $info  | out-String


$pass = ConvertTo-SecureString "whatever" -asplaintext -force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "NT AUTHORITY\ANONYMOUS LOGON", $pass

Send-MailMessage -From $from -To $to -Subject $subj -Body $body  -SmtpServer "mail01" -Encoding UTF8 -Credential $creds
