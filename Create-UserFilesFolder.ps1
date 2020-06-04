import-module activedirectory

## DEBUG global preference
# For console debugging, set to '0' in product
$global:DEBUG = 0
# Log file name - leave empty to use script name
$global:cLFName = ""

## Script preferences
# Preference XML file name
$cOptionsFileName = ""

# Load Modules and PSSnapins
Remove-Module -Name BB-PSTools -ErrorAction SilentlyContinue
Import-Module -Name C:\Var\Scripts\BB-PSTools\BB-PSTools -ErrorAction SilentlyContinue
if (-not (Get-Command -Module BB-PSTools -Name "Send-BBMailMessage" -ErrorAction SilentlyContinue)) {
	Write-Error "Error loading BB-PSTools"
	exit 1
}


#основные функции

function AddNTFSPermissions($path, $object, $permission) {
    $FileSystemRights = [System.Security.AccessControl.FileSystemRights]$permission
    $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $PropagationFlag = [System.Security.AccessControl.PropagationFlags]"None"
    $AccessControlType =[System.Security.AccessControl.AccessControlType]::Allow
    $Account = New-Object System.Security.Principal.NTAccount($object)
    $FileSystemAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Account, $FileSystemRights, $InheritanceFlag, $PropagationFlag, $AccessControlType)
    $DirectorySecurity = Get-ACL $path
    $DirectorySecurity.AddAccessRule($FileSystemAccessRule)
    Set-ACL $path -AclObject $DirectorySecurity
}

function RemoveNTFSPermissions($path, $object, $permission) {
    $FileSystemRights = [System.Security.AccessControl.FileSystemRights]$permission
    $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $PropagationFlag = [System.Security.AccessControl.PropagationFlags]"None"
    $AccessControlType =[System.Security.AccessControl.AccessControlType]::Allow
    $Account = New-Object System.Security.Principal.NTAccount($object)
    $FileSystemAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Account, $FileSystemRights, $InheritanceFlag, $PropagationFlag, $AccessControlType)
    $DirectorySecurity = Get-ACL $path
    $DirectorySecurity.RemoveAccessRuleAll($FileSystemAccessRule)
    Set-ACL $path -AclObject $DirectorySecurity
}

function RemoveInheritance($path) {
    $isProtected = $true
    $preserveInheritance = $true
    $DirectorySecurity = Get-ACL $path
    $DirectorySecurity.SetAccessRuleProtection($isProtected, $preserveInheritance)
    Set-ACL $path -AclObject $DirectorySecurity
}

# собираем данные

$string = $env:COMPUTERNAME
$Site = $string.Remove(3)

$Users = Get-ADUser -Filter * -SearchBase "OU=Users,OU=$Site,OU=DOMAIN,DC=bb,DC=local" | Select-Object -Property name,SamAccountName

#$UserFilesResticted = Get-ADGroupMember "UserFiles Exception" | Select-Object -Property name
$UserFilesResticted =Get-ADGroupMember -Identity S-1-5-21-2368781600-2167854719-1865721655-3380 | Select-Object -Property name
$Path = "F:\Shares\UserFiles\"
$UserFilesFolders = Get-ChildItem $Path | Select-Object -Property name


foreach ($User in $Users) {

#если юзер в группе UserFiles Exception - ниче не делаем

    if ($User.name -in $UserFilesResticted.name)
        {<#Write-Log ($User.name +" Without Userfiles Folder")#>}
    else {
#юзер не в группе - проверяем создана ли папка
        if($User.name -in $UserFilesFolders.name)
            {

#юзер не в группе, папка есть - проверяем права, добавляем если не корректны!

            #Write-Log "$User.Name Folder Already Exists"
            $PathFoldertmp = $Path + $User.Name
            $acltmp = Get-Acl -Path $PathFoldertmp
            $tmp = @()

            foreach ($a in $acltmp.Access){$tmp += $a.IdentityReference.Value}

            if ("DOMAIN\"+$User.SamAccountName -in $tmp )
                { foreach ($a in $acltmp.Access) {
                    if ( ($a.IdentityReference.Value -eq "DOMAIN\"+$User.SamAccountName) -and ($a.FileSystemRights -like "Modify*") ) {<#Write-Log ($User.name +" Folder Already Exists and Rigths are correct : nothing to do")#>}
                    elseif ( ($a.IdentityReference.Value -eq "DOMAIN\"+$User.SamAccountName) -and ($a.FileSystemRights -notlike "Modify*") ) {Write-Log ($User.name  +" Folder Already Exists, but Rights are not correct : Modify was Added"); AddNTFSPermissions $PathFolder $User.SamAccountName "Modify" }
                    }

                }
            else {Write-Log ($User.name +" Folder Already Exists, but User and Rights are not correct : User and Modify were Added"); AddNTFSPermissions $PathFolder $User.SamAccountName "Modify"}


            }
        else {
#юзер не в группе и папки нет - создаем
            $PathFolder = $Path + $User.Name
            # создаем папку
            New-Item -Path $PathFolder -ItemType Directory

            #снимаем наследование
            RemoveInheritance $PathFolder

            # убираем для остальных
            #RemoveNTFSPermissions $PathFolder "Authenticated Users" "Modify, ChangePermissions"
            RemoveNTFSPermissions $PathFolder "Users" "Modify, ChangePermissions"

            # добавляем права для пользователя
            AddNTFSPermissions $PathFolder $User.SamAccountName "Modify"


            Write-Log ($User.Name +" Folder Created and correct Rights were Set")

            }





        }




}
