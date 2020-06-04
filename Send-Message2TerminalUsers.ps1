
Param (
	[Parameter(Position = 0)]
	[Alias("Message")]
	[String]$MessageText = "Просьба завершить сеанс!",
	[Parameter(Position = 1)]
	[Alias("Server")]
	#[String[]]$TerminalTarget = @("term03.bb.local", "term02.bb.local", "term01.bb.local")
    [String[]]$TerminalTarget = @("term03.bb.local")
)

#cls
$SessionHostCollection = "BC1-RDS"
# Блок интерактива, тут добавляем мессадж и на какую терминалку отправляем
$MessageTitle = "Сообщение от отдела ИТ"
#$MessageText = "Просьба завершить сеанс!"

try
{
	$Brokers = Resolve-DnsName "rd.domain.ru" -ErrorAction Stop | % { Get-RDConnectionBrokerHighAvailability (Resolve-DnsName $_.IPAddress).NameHost -ErrorAction Stop }


	If ($Brokers[0].ActiveManagementServer -ne $null) { $ConnectionBroker = $Brokers[0].ActiveManagementServer }
	Elseif ($Brokers[1].ActiveManagementServer -ne $null) { $ConnectionBroker = $Brokers[1].ActiveManagementServer }
	Else { throw "Error, Connection Broker is not found" }

	$Sessions = Get-RDUserSession -ConnectionBroker $ConnectionBroker -CollectionName $SessionHostCollection -ErrorAction Stop | Where { $_.HostServer -in $TerminalTarget }

	ForEach ($Session in $Sessions)
	{
		Send-RDUserMessage -HostServer $Session.ServerName -UnifiedSessionID $Session.UnifiedSessionID -MessageTitle $MessageTitle -MessageBody $MessageText -ErrorAction Stop

	}
}
catch
{
	$ErrorMessage = $_.Exception.Message
	$FailedItem = $_.Exception.ItemName

	Write-Host "Error: $ErrorMessage $FailedItem"
	break
}
finally
{
	#Cleanup
	#Write-Host "Done."
}
