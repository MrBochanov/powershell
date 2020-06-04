##################
cls
function global:TranslitToLAT
{
param([string]$inString)
$Translit_To_LAT = @{
[char]'а' = "a"
[char]'А' = "a"
[char]'б' = "b"
[char]'Б' = "b"
[char]'в' = "v"
[char]'В' = "v"
[char]'г' = "g"
[char]'Г' = "g"
[char]'д' = "d"
[char]'Д' = "d"
[char]'е' = "e"
[char]'Е' = "e"
[char]'ё' = "e"
[char]'Ё' = "e"
[char]'ж' = "zh"
[char]'Ж' = "zh"
[char]'з' = "z"
[char]'З' = "z"
[char]'и' = "i"
[char]'И' = "i"
[char]'й' = "i"
[char]'Й' = "i"
[char]'к' = "k"
[char]'К' = "k"
[char]'л' = "l"
[char]'Л' = "l"
[char]'м' = "m"
[char]'М' = "m"
[char]'н' = "n"
[char]'Н' = "n"
[char]'о' = "o"
[char]'О' = "o"
[char]'п' = "p"
[char]'П' = "p"
[char]'р' = "r"
[char]'Р' = "r"
[char]'с' = "s"
[char]'С' = "s"
[char]'т' = "t"
[char]'Т' = "t"
[char]'у' = "u"
[char]'У' = "u"
[char]'ф' = "f"
[char]'Ф' = "f"
[char]'х' = "kh"
[char]'Х' = "kh"
[char]'ц' = "tc"
[char]'Ц' = "tc"
[char]'ч' = "ch"
[char]'Ч' = "ch"
[char]'ш' = "sh"
[char]'Ш' = "sh"
[char]'щ' = "shch"
[char]'Щ' = "shch"
[char]'ъ' = "" # "``"
[char]'Ъ' = "" # "``"
[char]'ы' = "y" # "y`"
[char]'Ы' = "y" # "Y`"
[char]'ь' = "" # "`"
[char]'Ь' = "" # "`"
[char]'э' = "e" # "e`"
[char]'Э' = "e" # "E`"
[char]'ю' = "yu"
[char]'Ю' = "yu"
[char]'я' = "ya"
[char]'Я' = "ya"
[char]' ' = "."
}
$outChars=""
foreach ($c in $inChars = $inString.ToCharArray())
{
if ($Translit_To_LAT[$c] -cne $Null )
{$outChars += $Translit_To_LAT[$c]}
else
{$outChars += $c}
}
Write-Output $outChars
}

#$text = "Текст который нужно транслитерировать"
#$log = TranslitToLAT $text
#$log
##################
cls
$user_firstname = Read-Host "Введите имя сотрудника"
$user_lastname = Read-Host "Введите фамилию сотрудника"

$sites = @("1","2","3","4","5")
$count = 0
cls
foreach ($s in $sites)
{
    $count++
    Write-Host $count": "$s
}
$input = read-host "Введите номер, соответсвующий Площадке из списка":
$user_site = $sites[$input-1]

$departments = get-aduser -searchbase "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL" -filter * -property department | select department | sort-object department -unique
$count = 0
cls
foreach ($d in $departments)
{
    $count++
    Write-Host $count": " -NoNewline
    Write-Host $d.department

}
$input = read-host "Введите номер, соответсвующий Отделу из списка":
$user_department = $departments[$input-1].department

$titles = get-aduser -searchbase "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL" -Filter {department -eq $user_department} -property title | select title | sort-object title -unique
$count = 0
cls
foreach ($t in $titles)
{
    $count++
    Write-Host $count": " -NoNewline
    Write-Host $t.title

}
$input = read-host "Введите номер, соответсвующий Должности из списка":
$user_title = $titles[$input-1].title
cls


$user_workphone = Read-Host "Введите внутренний телефон сотрудника"
$user_mobile = Read-Host "Введите мобильный телефон сотрудника"



$user_login = TranslitToLAT $user_firstname" "$user_lastname
$user_displayname = $user_lastname+" "+$user_firstname



Write-Host "Готов создать сотрудника" -BackgroundColor Green
Write-Host "Отображаемое имя сотрудника" $user_displayname
Write-Host "Фамилия сотрудника" $user_lastname
Write-Host "Login сотрудника" $user_login
write-host "Вы выбрали площадку" $user_site
write-host "Вы выбрали отдел" $user_department
write-host "Вы выбрали должность" $user_title
write-host "Внутренний телефон сотрудника" $user_workphone
write-host "Мобильный телефон сотрудника" $user_mobile

$template = get-aduser -searchbase "OU=Users,OU=$user_site,OU=BIGBOX,DC=BB,DC=LOCAL" -filter {department -eq $user_department -And title -eq $user_title} -Properties Name,sAMAccountName

Write-Host "Предполагаемый аналог" $template.Name -BackgroundColor DarkYellow -NoNewline
if ($template.Count -ne 0)
{
    $groups = (Get-ADUser -Identity $template.sAMAccountName -Properties memberof).memberof
    Write-Host " является членом следующих групп:"
        foreach ($g in $groups)
            {
                write-host $g

            }
    $yesNo = Read-Host "Добавить нового сотрудника в те же группы? (Y/n)"

    If ($yesNo -eq "y")
    {
        Write-Host Вы ответили Да
        $yesNo = Read-Host "Cоздать пользователя?(Y/n)"
            If ($yesNo -eq "y")
            {
                Write-Host Создаем пользователя
                #New-ADUser -sAMAccountName $user_login -GivenName $user_firstname -Surname $user_lastname -DisplayName $user
            }
        #Get-ADUser -Identity $template -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $newuser
    }
    Else
    {
        Write-Host "В группы не добавляем"
        $yesNo = Read-Host "Cоздать пользователя с пустыми группами?(Y/n)"

            If ($yesNo -eq "y")
            {

                Write-Host Создаем пользователя с пустыми группами
                #Get-ADUser -Identity $template -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $newuser


            }

    }

}
Else
{
    Write-Host "Аналогов нет"
    $yesNo = Read-Host "Cоздать пользователя с пустыми группами?(Y/n)"

    If ($yesNo -eq "y")
    {

        Write-Host Создаем пользователя с пустыми группами
        #Get-ADUser -Identity $template -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $newuser
    }

}
