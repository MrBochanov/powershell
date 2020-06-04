$sessionuser = "domain\user";
$sessionpass = ConvertTo-SecureString -String "12345678" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sessionuser, $sessionpass


$session = New-PSSession -ComputerName "domain.bb.local" -Credential ($Credential)
Invoke-Command $session -Scriptblock { Import-Module ActiveDirectory }
Import-PSSession -Session $session -module ActiveDirectory

$username = $env:USERNAME

$user = Get-ADUser $username

$DestinationFolder = "Y:\"+$user.Name + "\VeeamBackup"

$c = Test-Path C:\VeeamBackup; if ($c -eq $true){$VeeamPath = "C:\VeeamBackup\*"}
$d = Test-Path D:\VeeamBackup; if ($d -eq $true){$VeeamPath = "D:\VeeamBackup\*"}



Copy-Item $VeeamPath $DestinationFolder -Recurse -ErrorAction SilentlyContinue
