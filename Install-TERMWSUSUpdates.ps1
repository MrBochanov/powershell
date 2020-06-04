Param()

Import-Module C:\Var\Scripts\PSWindowsUpdate
Import-Module RemoteDesktop

#выявляем соседний хост для проверки

$Hostname = HostName

#if ( ($Hostname.Substring( [math]::Max( 0, $Hostname.Length – 1 ) )) -eq "1") {  $CheckHostname = $Hostname.Substring(0,$Hostname.Length-1) + "2"  }
#if ( ($Hostname.Substring( [math]::Max( 0, $Hostname.Length – 1 ) )) -eq "2") {  $CheckHostname = $Hostname.Substring(0,$Hostname.Length-1) + "1"  }
if ($Hostname -like "*01") {  $CheckHostname = $Hostname.Substring(0,$Hostname.Length-1) + "2"  }
if ($Hostname -like "*02") {  $CheckHostname = $Hostname.Substring(0,$Hostname.Length-1) + "1"  }

$CheckHostname

# проверка его доступности перед запуском обновлений и перезагрузки

$TimeEnd = (get-date).addminutes(2)

Do {
    $TimeNow = Get-Date
#A: Ping partner
    if (Test-Connection $CheckHostname -Count 1 -ErrorAction SilentlyContinue) {$A = $true}
    else {$A = $false; Write-Host "Ping failed"; Start-Sleep -s 3 }
    }
Until ($TimeNow.CompareTo($TimeEnd) -lt 1 -or ( $A ))

# проверка обновлений, затем проверка активного брокера, перекидывание роли в случае обнаружения

$d = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
If ($A) {
    $kbl = @()

    Get-WUList | ? { $_.Status -match 'D'} | % { $kbl += $_.KB }
    if ($kbl) {
        $IamBroker = Get-RDConnectionBrokerHighAvailability -ErrorAction Continue
        $IamNOTBroker = Get-RDConnectionBrokerHighAvailability "$CheckHostname.bb.local" -ErrorAction Continue

        If ($IamBroker) {
            Set-RDActiveManagementServer $CheckHostname
            Start-Sleep -s 600

            Do {$TEST = Get-RDConnectionBrokerHighAvailability "$CheckHostname.bb.local" -ErrorAction Continue}
            Until ($TEST)

            "$d Updates are found and going to install: $($kbl -join ',')" | Out-File C:\Var\Log\Updatelog.txt -Append
            Get-WUInstall -KBArticleID $kbl -AutoReboot -AcceptAll -WhatIf
        }
        Elseif ($IamNOTBroker) {
            "$d Updates are found and going to install: $($kbl -join ',')" | Out-File C:\Var\Log\Updatelog.txt -Append
            Get-WUInstall -KBArticleID $kbl -AutoReboot -AcceptAll -WhatIf
        }
        Else {
            "$d Something went wrong: Connection Broker is not available (not moved!)" | Out-File C:\Var\Log\Updatelog.txt -Append
        }
    } else {
        "$d Nothing to Install" | Out-File C:\Var\Log\Updatelog.txt -Append
    }
} else {
    "$d Something went wrong: Another TERM is not available" | Out-File C:\Var\Log\Updatelog.txt -Append
}
