Param()

# исходные данные - названия комплексов - 3 буквы, Ip - первые 2 октета с тчк
$OLDBOX = "MRM"
$OLDBOXIP = "10.5."
$NEWBOX = "MTS"
$NEWBOXIP = "10.130."

# запрос текущих записей
$Records = Get-DnsServerResourceRecord -ZoneName "service.local" -RRType "A" |  Where-Object {$_.HostName -like "$OLDBOX*"}


foreach ($Record in $Records) {

        $NewHost = $Record.HostName -replace $OLDBOX,$NEWBOX
        #$NewHost = $Record.HostName -replace "mrm","mts"
        #$NewIPAddress = $Record.RecordData.IPv4Address -replace "10.5.","10.130."
        $NewIPAddress = $Record.RecordData.IPv4Address -replace $OLDBOXIP,$NEWBOXIP

# проверяем зоны, создаем в случае не обнаружения

        #$NewIPAddress -match "10.([\d]{3}).([\d]).*"
        $NewIPAddress -match "10.([\d]+).([\d]+).*"
        $Zonename = $Matches[2]+"."+$Matches[1]+".10.*"

        if (Get-DnsServerZone | Where-Object {$_.Zonename -like "$Zonename"} ) {Write-Host "$Zonename already exists. Nothing to do!"}
        Else {

                $NetworkID = "10."+$Matches[1]+"."+$Matches[2]+".0/24"
                Add-DnsServerPrimaryZone -DynamicUpdate Secure -NetworkId $NetworkID -ReplicationScope Domain

                }

# проверяем днc записи, добавляем в случае не обнаружения

        If (Get-DnsServerResourceRecord -Name $NewHost -ZoneName "service.local" -RRType "A" -ErrorAction SilentlyContinue) { Write-Host "$NewHost already in Service.Local. Nothing to do!" }
        Else {
          Add-DnsServerResourceRecordA -Name $NewHost -ZoneName "service.local" -IPv4Address $NewIPAddress -CreatePtr
        }

        }
