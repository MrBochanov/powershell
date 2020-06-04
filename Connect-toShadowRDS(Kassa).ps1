#сбор инфы про сессии, выделение кассовых, создание моднейшей таблицы,вывод на экран
$TerminalServers = Get-ADComputer  -Filter 'description -notlike "*Brocker*"' -SearchBase "OU=RDS,OU=Servers,OU=DOMAIN,DC=bb,DC=local" -Properties Name | select -Property Name
#$TerminalServers = "term03", "term04", "term05", "term06"
$kassas = @()

foreach ($TerminalServer in $TerminalServers){
    $server = $TerminalServer.Name
    $Sessions  =  query user /server:$server
    foreach ($Session in $Sessions){
        $SessionDetails =  $Session -split '\s+'
        if ($SessionDetails[1] -like "kassa*") {
            $kassa = @()
            if ($SessionDetails[2] -like "rdp*") { $kassa = New-Object -TypeName psobject -Property @{Name=$SessionDetails[1]; State="ACTIVE"; ID=$SessionDetails[3]; Logontime=$SessionDetails[6] +" "+ $SessionDetails[7];Server=$server} }
            else {$kassa = New-Object -TypeName psobject -Property @{Name=$SessionDetails[1]; State="DISCONNECTED"; ID=$SessionDetails[2]; Logontime=$SessionDetails[5] + $SessionDetails[6]} }
            $kassas += $kassa
         }
    }
}

$kassas | select -Property Name,ID,State, Server, Logontime | Sort-Object -Property Name | Format-Table -AutoSize

$123 = $kassas | select -Property Name,ID,State, Server, Logontime | Sort-Object -Property Name

#спрос юзера о нужной сессии, определние сервера, на котором запущена
$YourID = Read-Host "Enter Session ID"

foreach ($kassa in $kassas) {
if ($kassa.ID -eq $YourID) {$YourServer = $kassa.Server}
}

#подключение
mstsc /shadow:$YourID /v:$YourServer /control /noConsentPrompt
