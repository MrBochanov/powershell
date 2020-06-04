# запускается вручную, создает пользователя в AD на основе другого


#translitfunction
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


#usersite detection
$sites = (Get-ADForest).sites

$count = 0
cls
foreach ($s in $sites)
{
    $count++
    Write-Host $count": "$s
}
$input = read-host "Введите номер, соответсвующий Площадке из списка"
$user_site = $sites[$input-1]

#userdepartment detection
$departments = get-aduser -searchbase "OU=Users,OU=$user_site,OU=BIGBOX,DC=BB,DC=LOCAL" -filter * -property department | select department | sort-object department -unique
$count = 0
cls
foreach ($d in $departments)
{
    $count++
    Write-Host $count": " -NoNewline
    Write-Host $d.department

}
$input = read-host "Введите номер, соответсвующий Отделу из списка, или 0, если Другой"
if ($input -eq "0") {$user_department = read-host "Какой"}
else {$user_department = $departments[$input-1].department}


#usertitle detection
$titles = get-aduser -searchbase "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL" -Filter {department -eq $user_department} -property title | select title | sort-object title -unique
$count = 0
cls
foreach ($t in $titles)
{
    $count++
    Write-Host $count": " -NoNewline
    Write-Host $t.title

}
$input = read-host "Введите номер, соответсвующий Должности из списка, или 0, если Другой"
if ($input -eq "0") {$user_title = read-host "Какой"; $check = "н"}
else {$user_title = $titles[$input-1].title}
cls

#unical information

$user_firstname = Read-Host "Введите имя сотрудника"
$user_lastname = Read-Host "Введите фамилию сотрудника"
$user_workphone = Read-Host "Введите внутренний телефон сотрудника"
$user_mobile = Read-Host "Введите мобильный телефон сотрудника"
$user_dr = Read-Host "Введите день рождения сотрудника = хх.хх.хххх"


if ($check -ne "н") {
Do {$check = read-host "Копируем группы с похожей учетки? (д/н)"} until (($check -eq "д") -or ($check -eq "н") )
}

if ($check -eq "д")

{

$templates = get-aduser -searchbase "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL" -filter {department -eq $user_department -And title -eq $user_title} -Properties Name,sAMAccountName

if ($templates.GetType().Name -ne "Object[]") {$user_template = $templates}
else {

    $count = 0
    foreach ($t in $templates)
    {
        $count++
        Write-Host $count": "$t
    }
    $input = read-host "Введите номер, соответсвующий Учетки из списка"
    $user_template = $templates[$input-1]

    }

    #выясняем общие поля, остальные копируем с темплейта

    $user_groups = Get-ADPrincipalGroupMembership $user_template | select name
    $user_template_full = Get-ADUser $user_template -Properties Pager, City,physicalDeliveryOfficeName,streetAddress,manager

    $user_pager = $user_template_full.pager
    $user_city = $user_template_full.city
    $user_physicalDeliveryOfficeName = $user_template_full.physicalDeliveryOfficeName
    $user_streetAddress = $user_template_full.streetAddress
    $user_manager = $user_template_full.manager

    $user_path = "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL"






    }
else {

    Write-Host "Без копирования"
    #выясняем общие поля, остальные без данных
    $templates = get-aduser -searchbase "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL" -filter *
    $count = $templates.Count/2
    $count = [math]::Truncate($count)
    $user_template = $templates[$count]

    $user_groups = $null
    $user_template_full = Get-ADUser $user_template -Properties Pager, City,physicalDeliveryOfficeName,streetAddress,manager

    $user_pager = $user_template_full.pager
    $user_city = $user_template_full.city
    $user_physicalDeliveryOfficeName = $user_template_full.physicalDeliveryOfficeName
    $user_streetAddress = $user_template_full.streetAddress
    $user_manager = $null

    $user_path = "OU=Users,OU=$user_site,OU=DOMAIN,DC=BB,DC=LOCAL"

    }


$user_login = TranslitToLAT $user_firstname" "$user_lastname
$user_displayname = $user_lastname+" "+$user_firstname

cls
Write-Host "Готов создать сотрудника" -BackgroundColor Green
Write-Host "Отображаемое имя сотрудника" $user_displayname
Write-Host "Фамилия сотрудника" $user_lastname
Write-Host "Login сотрудника" $user_login
write-host "Вы выбрали площадку" $user_site
write-host "Вы выбрали отдел" $user_department
write-host "Вы выбрали должность" $user_title
write-host "Внутренний телефон сотрудника" $user_workphone
write-host "Мобильный телефон сотрудника" $user_mobile
write-host "День рождения сотрудника" $user_dr

write-host "Городской телефон сотрудника" $user_pager
write-host "Город" $user_city
write-host "Физическая площадка" $user_physicalDeliveryOfficeName
write-host "Адрес офиса" $user_streetAddress

if ($user_manager -eq $null) {write-host "Менеджер сотрудника : ЗАПОЛНИТЬ!"} else {write-host "Менеджер сотрудника" $user_manager}

if ($user_groups -eq $null) {write-host "Группы сотрудника : ЗАПОЛНИТЬ!"} else{ write-host "Группы сотрудника" $user_groups.name}


Write-Host "Создаём?? (д/н)" -BackgroundColor Green

Do {$check = read-host } until (($check -eq "д") -or ($check -eq "н") )
if ($check -eq "д") {



    New-ADUser -SamAccountName $user_login `
    -Name $user_displayname `
    -UserPrincipalName $user_login"@bb.local" `
    -GivenName $user_firstname `
    -Surname $user_lastname `
    -DisplayName $user_displayname `
    -Path $user_path `
    -AccountPassword  (ConvertTo-SecureString "Qwerty123" -AsPlainText -Force) `
    -ChangePasswordAtLogon $True `
    -City $user_city `
    -Department $user_department `
    -Title $user_title `
    -MobilePhone $user_mobile `
    -Office $user_physicalDeliveryOfficeName `
    -OfficePhone $user_workphone `
    -Enabled $true `
    -Company "COMPANY" `
    -OtherAttributes @{'pager'= $user_pager;'extensionAttribute1' = $user_dr; 'streetAddress' = $user_streetAddress }

    if ($user_manager -eq $null) {} else { Set-AdUser -Identity $user_login -Manager $user_manager}
    if ($user_groups -eq $null) {} else {

        foreach ($group in $user_groups) {Add-ADGroupMember -Identity $group.name -Members $user_login}

        }

    }
