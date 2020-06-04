Param()

Do {
$UserName = $env:username
$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = $Filter
$ADUserPath = $Searcher.FindOne()
$ADUser = $ADUserPath.GetDirectoryEntry()
} Until ($ADUser -ne $null)

if ($ADUser.Parent -like "*OU=DOMAIN,DC=bb,DC=local") {


if ($ADUser.sAMAccountName -notlike "sa_*") {

#Стартуем скрипт в режиме x86
#if ($env:Processor_Architecture -ne "x86")
#{ write-warning 'Стартуем PowerShell x86'
#&"$env:windir\syswow64\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -File $myinvocation.Mycommand.path -ExecutionPolicy bypass

#Основные переменные
$TemplateName = 'CorpSignature'
$DomainName = 'fs'
$SigSource = "\\$DomainName\Public\Podpis"
$DefaultAddress = "Wall Street"
$DefaultPOBox = '666'
$DefaultCity = 'Central City'
$DefaultTelephone = '911'
$DefaultFax = '912'

#Переменные для локального и удаленного расположения подписи
$AppData=(Get-Item env:appdata).value
$SigPath = '\Microsoft\Signatures'
$LocalSignaturePath = $AppData+$SigPath
$RemoteSignaturePathFull = $SigSource+'\'+$TemplateName+'.docx'
$fullPath = $LocalSignaturePath+'\'+$TemplateName+'.docx'



$isfile = Test-Path $LocalSignaturePath
if($isfile -eq "True") {
   #Write-host "Файл существует"
}
else {
   #Write-host "Файл не существует"
   New-Item $LocalSignaturePath -type directory
}




#Получаем информацию для текущего пользователя из Active Directory
$UserName = $env:username
$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = $Filter
$ADUserPath = $Searcher.FindOne()
$ADUser = $ADUserPath.GetDirectoryEntry()
$ADDisplayName = $ADUser.DisplayName
$ADTitle = $ADUser.title
$ADCompany = $ADUser.company
$ADStreetAddress = $ADUser.streetaddress
$ADPOBox = $ADUser.postofficebox
$ADCity = $ADUser.l
$ADTelePhoneNumber = $ADUser.TelephoneNumber
$ADFax = $ADUser.facsimileTelephoneNumber
$ADMobile = $ADUser.mobile
$ADWebSite = $ADUser.wWWHomePage
$ADEmailAddress = $ADUser.mail
$ADPager = $ADUser.pager


#Копируем файл, если таковой отсутствует в целевой папке или если его хэш отличается от исходного
If (!(Test-Path -Path $fullPath)) {
Copy-Item $RemoteSignaturePathFull $LocalSignaturePath -Recurse -Force
}
Else {


#$Rem = Get-FileHash $RemoteSignaturePathFull -Algorithm SHA256

$md51 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$hash1 = [System.BitConverter]::ToString($md51.ComputeHash([System.IO.File]::ReadAllBytes($RemoteSignaturePathFull)))

#$loc = Get-FileHash $fullPath -Algorithm SHA256

$md52 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$hash2 = [System.BitConverter]::ToString($md52.ComputeHash([System.IO.File]::ReadAllBytes($fullPath)))

#Write-Host $Rem.Hash
#Write-Host $loc.Hash


If ($hash1 -ne $hash2)
{
Copy-Item $RemoteSignaturePathFull $LocalSignaturePath -Recurse -Force
Write-Host "КОПИРУЮ"
} Else {
Write-Host "ХЭШИ СОВПАДАЮТ"}
}

$ReplaceAll = 2
$FindContinue = 1
$MatchCase = $False
$MatchWholeWord = $True
$MatchWildcards = $False
$MatchSoundsLike = $False
$MatchAllWordForms = $False
$Forward = $True
$Wrap = $FindContinue
$Format = $False

#Начинаем вытягивать данные из Active Directory
[Void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Interop.Word")
$WordTmpl = New-Object -comObject Word.Application
$WordTmpl.Visible = $False
$objDoc = $WordTmpl.Documents.Open($fullPath)
$objSelection = $WordTmpl.Selection

#Определяем имя
$Bookmark = "displayName"
$ReplaceText = $ADDisplayName
$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
$RangeNew.Text = $ReplaceText.ToString()

    #Определяем должность
    $Bookmark = "title"
    $ReplaceText = $ADTitle
    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    $RangeNew.Text = $ReplaceText.ToString()


    #Определяем мобилку
    #$Bookmark = "mobile"
    #$ReplaceText = $ADMobile -replace '^(..)(...)(...)(..)(..)$','$1 ($2) $3-$4-$5'
    #$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #$RangeNew.Text = $ReplaceText[0]

    #Определяем городской телефон
    $Bookmark = "pager"
    $ReplaceText = $ADPager #-replace '^(..)(...)(...)(..)(..)$','$1 ($2) $3-$4-$5'
    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    $RangeNew.Text = $ReplaceText[0]

    #Название компании
    #$Bookmark = "company"
    #$ReplaceText = $ADCompany
    #$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #$RangeNew.Text = $ReplaceText.ToString()

    #Адрес пользователя с проверкой на заполнение атрибута
	#$Bookmark = "streetAddress"
	#If ($ADStreetAddress.ToString() -eq '') {
	#	$ReplaceText = $DefaultAddress
	#} Else {
    #    $ReplaceText = $ADStreetAddress.ToString()
	#}
	#	$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #    $RangeNew.Text = $ReplaceText.ToString()

    #Адрес пользователя
    $Bookmark = "streetAddress"
    $ReplaceText = $ADStreetAddress
    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    $RangeNew.Text = $ReplaceText.ToString()

    #Город
    $Bookmark = "l"
    $ReplaceText = $ADCity
    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    $RangeNew.Text = $ReplaceText.ToString()

    #Внутренний номер
    $Bookmark = "TelephoneNumber"
    $ReplaceText = $ADTelephoneNumber
    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    $RangeNew.Text = $ReplaceText.ToString()

    #Почтовый ящик пользователя с проверкой на заполнение атрибута
	#$Bookmark = "postOfficeBox"
	#If ($ADPOBox.ToString() -eq '') {
	#	$ReplaceText = $DefaultPOBox
	#} Else {
	#	$ReplaceText = $ADPOBox.ToString()
	#}
    #    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #    $RangeNew.Text = $ReplaceText.ToString()

    #Город пользователя с проверкой на заполнение атрибута
	#$Bookmark = "l"
	#If ($ADCity.ToString() -eq '') {
	#	$ReplaceText = $DefaultCity
	#} Else {
	#	$ReplaceText = $ADCity.ToString()
	#}
	#	$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #    $RangeNew.Text = $ReplaceText.ToString()

    #Рабочий телефон с проверкой на заполнение атрибута
	#$Bookmark = "telephoneNumber"
	#If ($ADTelePhoneNumber.ToString() -eq '') {
	#	$ReplaceText = $DefaultTelephone
	#} Else {
    #    $ReplaceText = $ADTelePhoneNumber.ToString()
	#}
	#	$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #    $RangeNew.Text = $ReplaceText.ToString()

    #Номер факса с проверкой на заполнение атрибута
    #$Bookmark = "facsimileTelephoneNumber"
    #If ($ADFax.ToString() -eq '') {
    #    $ReplaceText = $DefaultFax
    #} Else {
    #    $ReplaceText = $ADFax.ToString()
    #}
    #if ($objDoc.Bookmarks.Exists($Bookmark)) {
    #    $RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #    $RangeNew.Text = $ReplaceText.ToString()
    #}

    #Номер мобильного, учитывая то, что в тексте 2 раза упоминается mobile
    #$FindText = "099"
    #$ReplaceText = $ADMobile.ToString()
    #$objSelection.Find.Execute($FindText,$MatchCase, $MatchWholeWord,$MatchWildcards,$MatchSoundsLike, $MatchAllWordForms,$Forward,$Wrap,$Format, $ReplaceText,$ReplaceAll)

    #Веб-сайт пользователя
    #$Bookmark = "wWWHomePage"
    #$ReplaceText = $ADWebSite.ToString()
    #$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #$Url = $objDoc.Hyperlinks.Add($RangeNew,$ReplaceText)

    #E-mail пользователя
    #$Bookmark = "mail"
    #$ReplaceText = $ADEmailAddress
    #$RangeNew = $objDoc.Bookmarks.Item($Bookmark).Range
    #$Email = $objDoc.Hyperlinks.Add($RangeNew,'mailto:'+ $ReplaceText)




	Write-Host 'Начинаем сохранять подписи'

	#Сохраняем в HTML
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatHTML");
	$path = $LocalSignaturePath+'\'+$TemplateName+".htm"
	$WordTmpl.ActiveDocument.saveas([ref]$path, [ref]$saveFormat)

	#Сохраняем в RTF
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatRTF");
	$path = $LocalSignaturePath+'\'+$TemplateName+".rtf"
	$WordTmpl.ActiveDocument.SaveAs([ref] $path, [ref]$saveFormat)

	#Сохраняем в TXT
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatText");
	$path = $LocalSignaturePath+'\'+$TemplateName+".txt"
	$WordTmpl.ActiveDocument.SaveAs([ref] $path, [ref]$SaveFormat)
	$WordTmpl.ActiveDocument.Close()
	$WordTmpl.Quit()
#}
#exit
}
}
