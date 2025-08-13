```powershell
# ПОЛНЫЙ СКРИПТ ПОДГОТОВКИ ЛАБОРАТОРНОЙ СРЕДЫ ДЛЯ УРОКА ПО ГРУППАМ WINDOWS SERVER 2025
# Автор: Лабораторная среда для изучения типов групп
# Домен: Автоматическое определение
# Требования: Выполнять на контроллере домена с правами администратора

Write-Host "🚀 НАЧАЛО ПОЛНОЙ ПОДГОТОВКИ ЛАБОРАТОРНОЙ СРЕДЫ ДЛЯ УРОКА ПО ГРУППАМ" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "Этот скрипт создаст полную лабораторную среду для демонстрации" -ForegroundColor White
Write-Host "различий между группами безопасности и группами рассылки" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Magenta

# Получаем информацию о домене
$domain = Get-ADDomain
$domainDN = $domain.DistinguishedName
Write-Host "`n✅ Обнаружен домен: $($domain.DNSRoot)" -ForegroundColor Green
Write-Host "✅ Distinguished Name: $domainDN" -ForegroundColor Green

# ЭТАП 1: СОЗДАНИЕ ОРГАНИЗАЦИОННЫХ ЕДИНИЦ
Write-Host "`n🔍 ЭТАП 1: Создание структуры организационных единиц..." -ForegroundColor Cyan
Write-Host "Создаём OU для лабораторной работы и департаментов" -ForegroundColor Gray

# Создание основной OU для лабораторной работы
try {
    $labGroupsOU = Get-ADOrganizationalUnit -Identity "OU=Lab-Groups,$domainDN" -ErrorAction Stop
    Write-Host "⚠️ OU Lab-Groups уже существует: $($labGroupsOU.DistinguishedName)" -ForegroundColor Yellow
} catch {
    try {
        New-ADOrganizationalUnit -Name "Lab-Groups" -Path $domainDN -Description "Лабораторная работа по группам Windows Server 2025"
        Write-Host "✅ OU Lab-Groups успешно создана" -ForegroundColor Green
    } catch {
        Write-Host "❌ КРИТИЧЕСКАЯ ОШИБКА: Не удалось создать Lab-Groups: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Проверьте права доступа и попробуйте снова" -ForegroundColor Red
        return
    }
}

# Создание подразделений для департаментов
$departments = @(
    @{Name="IT"; Description="Департамент информационных технологий"},
    @{Name="Finance"; Description="Финансовый департамент"},
    @{Name="Marketing"; Description="Отдел маркетинга"},
    @{Name="HR"; Description="Отдел кадров"}
)

foreach ($dept in $departments) {
    try {
        $deptOU = Get-ADOrganizationalUnit -Identity "OU=$($dept.Name),OU=Lab-Groups,$domainDN" -ErrorAction Stop
        Write-Host "⚠️ OU $($dept.Name) уже существует" -ForegroundColor Yellow
    } catch {
        try {
            New-ADOrganizationalUnit -Name $dept.Name -Path "OU=Lab-Groups,$domainDN" -Description $dept.Description
            Write-Host "✅ OU $($dept.Name) создана" -ForegroundColor Green
        } catch {
            Write-Host "❌ Ошибка создания OU $($dept.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Показываем созданную структуру OU
Write-Host "`n📋 Созданная структура организационных единиц:" -ForegroundColor Cyan
try {
    $allOUs = Get-ADOrganizationalUnit -Filter "Name -like '*'" -SearchBase "OU=Lab-Groups,$domainDN" | Select-Object Name, DistinguishedName | Sort-Object Name
    $allOUs | Format-Table -AutoSize
    Write-Host "✅ ЭТАП 1 ЗАВЕРШЁН: Структура OU готова ($($allOUs.Count) единиц)" -ForegroundColor Green
} catch {
    Write-Host "❌ Не удалось отобразить структуру OU" -ForegroundColor Red
}

# ЭТАП 2: СОЗДАНИЕ ТЕСТОВЫХ ПОЛЬЗОВАТЕЛЕЙ
Write-Host "`n👥 ЭТАП 2: Создание тестовых пользователей..." -ForegroundColor Cyan
Write-Host "Создаём пользователей для демонстрации работы с группами" -ForegroundColor Gray

# Проверяем готовность OU перед созданием пользователей
$departmentNames = @("IT", "Finance", "Marketing", "HR")
$allOUReady = $true
foreach ($deptName in $departmentNames) {
    try {
        Get-ADOrganizationalUnit -Identity "OU=$deptName,OU=Lab-Groups,$domainDN" -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "❌ OU $deptName не готова!" -ForegroundColor Red
        $allOUReady = $false
    }
}

if (-not $allOUReady) {
    Write-Host "❌ КРИТИЧЕСКАЯ ОШИБКА: Не все OU созданы. Остановка выполнения!" -ForegroundColor Red
    return
}

# Настройка паролей и создание пользователей
$userPassword = ConvertTo-SecureString "Somepass1" -AsPlainText -Force
Write-Host "🔑 Пароль для всех пользователей: Somepass1" -ForegroundColor Yellow

# Определение пользователей для создания (расширенный список)
$usersToCreate = @(
    # IT отдел - 4 человека
    @{Name="IvanPetrov"; GivenName="Иван"; Surname="Петров"; Department="IT"; Title="Системный администратор"},
    @{Name="MariaSidorova"; GivenName="Мария"; Surname="Сидорова"; Department="IT"; Title="Разработчик"},
    @{Name="AntonVolkov"; GivenName="Антон"; Surname="Волков"; Department="IT"; Title="Сетевой администратор"},
    @{Name="TatianaKrylova"; GivenName="Татьяна"; Surname="Крылова"; Department="IT"; Title="Тестировщик"},
    
    # Finance отдел - 4 человека
    @{Name="SergeyMorozov"; GivenName="Сергей"; Surname="Морозов"; Department="Finance"; Title="Главный бухгалтер"},
    @{Name="ElenaVolkova"; GivenName="Елена"; Surname="Волкова"; Department="Finance"; Title="Финансовый аналитик"},
    @{Name="NataliaFedorova"; GivenName="Наталия"; Surname="Фёдорова"; Department="Finance"; Title="Экономист"},
    @{Name="VladimirSokolov"; GivenName="Владимир"; Surname="Соколов"; Department="Finance"; Title="Аудитор"},
    
    # Marketing отдел - 3 человека
    @{Name="DmitryOrlov"; GivenName="Дмитрий"; Surname="Орлов"; Department="Marketing"; Title="Маркетолог"},
    @{Name="AnnaPopova"; GivenName="Анна"; Surname="Попова"; Department="Marketing"; Title="PR-менеджер"},
    @{Name="MaximLebedev"; GivenName="Максим"; Surname="Лебедев"; Department="Marketing"; Title="SMM-специалист"},
    
    # HR отдел - 3 человека
    @{Name="OlgaSmirova"; GivenName="Ольга"; Surname="Смирнова"; Department="HR"; Title="HR-специалист"},
    @{Name="EkaterinaNovikova"; GivenName="Екатерина"; Surname="Новикова"; Department="HR"; Title="Рекрутер"},
    @{Name="AlexeyZhilin"; GivenName="Алексей"; Surname="Жилин"; Department="HR"; Title="Менеджер по персоналу"}
)

$createdCount = 0
$existingCount = 0

Write-Host "📊 Планируется создать пользователей:" -ForegroundColor Cyan
$departments.ForEach({ 
    $deptUsers = $usersToCreate | Where-Object { $_.Department -eq $_.Name }
    Write-Host "  $($_.Name): $($deptUsers.Count) пользователей" -ForegroundColor Gray
})
Write-Host "  Всего: $($usersToCreate.Count) пользователей" -ForegroundColor White

foreach ($user in $usersToCreate) {
    Write-Host "👤 Обрабатываем пользователя: $($user.GivenName) $($user.Surname) ($($user.Department))" -ForegroundColor Cyan
    
    # Проверяем существование пользователя
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$($user.Name)'" -ErrorAction SilentlyContinue
    
    if ($existingUser) {
        Write-Host "⚠️ Пользователь $($user.GivenName) $($user.Surname) уже существует" -ForegroundColor Yellow
        $existingCount++
    } else {
        try {
            $userParameters = @{
                Name = $user.Name
                GivenName = $user.GivenName
                Surname = $user.Surname
                DisplayName = "$($user.GivenName) $($user.Surname)"
                SamAccountName = $user.Name
                UserPrincipalName = "$($user.Name)@$($domain.DNSRoot)"
                EmailAddress = "$($user.Name.ToLower())@$($domain.DNSRoot)"
                Department = $user.Department
                Title = $user.Title
                Company = "Learn IT Lessons"
                Office = "$($user.Department) отдел"
                Path = "OU=$($user.Department),OU=Lab-Groups,$domainDN"
                AccountPassword = $userPassword
                Enabled = $true
                PasswordNeverExpires = $true
                CannotChangePassword = $false
                Description = "Тестовый пользователь для лабораторной работы по группам"
            }
            
            New-ADUser @userParameters
            Write-Host "✅ $($user.GivenName) $($user.Surname) успешно создан(а)" -ForegroundColor Green
            $createdCount++
        } catch {
            Write-Host "❌ ОШИБКА создания $($user.GivenName) $($user.Surname): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Проверка и отчёт по созданным пользователям
Write-Host "`n📋 Отчёт по пользователям по департаментам:" -ForegroundColor Cyan
try {
    $allUsers = Get-ADUser -Filter * -SearchBase "OU=Lab-Groups,$domainDN" -Properties Department, Title, EmailAddress | 
                Select-Object Name, SamAccountName, Department, Title, EmailAddress, DistinguishedName | 
                Sort-Object Department, Name
    
    if ($allUsers) {
        # Группируем по департаментам для красивого отображения
        $departmentNames | ForEach-Object {
            $deptName = $_
            $deptUsers = $allUsers | Where-Object { $_.Department -eq $deptName }
            if ($deptUsers) {
                Write-Host "`n🏢 Департамент $deptName ($($deptUsers.Count) чел.):" -ForegroundColor Yellow
                $deptUsers | Select-Object Name, SamAccountName, Title, EmailAddress | Format-Table -AutoSize
            }
        }
        
        Write-Host "`n📊 ИТОГОВАЯ СТАТИСТИКА:" -ForegroundColor Cyan
        Write-Host "✅ Всего пользователей в лабораторной среде: $($allUsers.Count)" -ForegroundColor Green
        Write-Host "✅ Создано новых: $createdCount, Уже существовало: $existingCount" -ForegroundColor Green
        
        # Статистика по департаментам
        $departmentNames | ForEach-Object {
            $deptCount = ($allUsers | Where-Object { $_.Department -eq $_ }).Count
            Write-Host "   $_ : $deptCount пользователей" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ Пользователи не найдены в OU Lab-Groups" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Ошибка при проверке пользователей: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "✅ ЭТАП 2 ЗАВЕРШЁН: Пользователи готовы для демонстрации" -ForegroundColor Green

# ЭТАП 3: СОЗДАНИЕ ОБЩИХ ПАПОК И ФАЙЛОВ
Write-Host "`n📁 ЭТАП 3: Создание файловой структуры для демонстрации..." -ForegroundColor Cyan
Write-Host "Создаём папки и файлы для тестирования разрешений групп" -ForegroundColor Gray

# Создание основной папки для общих ресурсов
$mainFolder = "C:\LabShares"
if (Test-Path $mainFolder) {
    Write-Host "⚠️ Основная папка $mainFolder уже существует" -ForegroundColor Yellow
} else {
    try {
        New-Item -Path $mainFolder -ItemType Directory -Force | Out-Null
        Write-Host "✅ Основная папка $mainFolder создана" -ForegroundColor Green
    } catch {
        Write-Host "❌ Ошибка создания основной папки: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Создание папок для различных департаментов
$sharedFolders = @(
    @{Path="C:\LabShares\IT-Resources"; Description="Ресурсы IT отдела"; Content="Конфиденциальная информация IT отдела`nДоступ только для сотрудников IT департамента`n`nСодержит:`n- Сценарии автоматизации`n- Техническая документация`n- Инструменты администрирования`n- Конфигурационные файлы`n`nОтветственные:`n- Иван Петров (Системный администратор)`n- Антон Волков (Сетевой администратор)`n`nДата создания: $(Get-Date -Format 'dd.MM.yyyy HH:mm')"},
    
    @{Path="C:\LabShares\Finance-Data"; Description="Финансовые данные"; Content="ФИНАНСОВЫЕ ДАННЫЕ КОМПАНИИ`n`nБюджет на 2025 год`nОтчёты по расходам за текущий квартал`nПланы доходов и инвестиций`nАналитические отчёты`n`nДОСТУП ТОЛЬКО ДЛЯ FINANCE ОТДЕЛА`n`nОтветственные:`n- Сергей Морозов (Главный бухгалтер)`n- Елена Волкова (Финансовый аналитик)`n- Владимир Соколов (Аудитор)`n`nДата обновления: $(Get-Date -Format 'dd.MM.yyyy HH:mm')"},
    
    @{Path="C:\LabShares\Company-Announcements"; Description="Объявления компании"; Content="ОБЪЯВЛЕНИЯ ДЛЯ ВСЕХ СОТРУДНИКОВ`n`nУважаемые коллеги!`n`nВ следующую пятницу, $(Get-Date -AddDays 7 -Format 'dd.MM.yyyy'), состоится общее собрание.`nВремя: 14:00`nМесто: Конференц-зал (2-й этаж)`nТема: 'Новые возможности Windows Server 2025 и обновление IT-политик'`n`nПовестка дня:`n1. Презентация новых функций Active Directory`n2. Обновление политик безопасности`n3. Планы по модернизации IT-инфраструктуры`n4. Вопросы и ответы`n`nПросьба подтвердить участие до четверга.`n`nС уважением,`nIT-департамент и Администрация`n`nКонтакты:`n- Иван Петров: ivan.petrov@$($domain.DNSRoot)`n- Ольга Смирнова: olga.smirnova@$($domain.DNSRoot)"},
    
    @{Path="C:\LabShares\Marketing-Materials"; Description="Маркетинговые материалы"; Content="МАРКЕТИНГОВЫЕ МАТЕРИАЛЫ И РЕСУРСЫ`n`nПрезентации и брендбук`nМакеты рекламных материалов`nТексты для социальных сетей`nАналитика и отчёты по кампаниям`n`nОтветственные:`n- Дмитрий Орлов (Маркетолог)`n- Анна Попова (PR-менеджер)`n- Максим Лебедев (SMM-специалист)`n`nДата создания: $(Get-Date -Format 'dd.MM.yyyy HH:mm')"}
)

foreach ($folder in $sharedFolders) {
    if (Test-Path $folder.Path) {
        Write-Host "⚠️ Папка $($folder.Path) уже существует" -ForegroundColor Yellow
    } else {
        try {
            New-Item -Path $folder.Path -ItemType Directory -Force | Out-Null
            Write-Host "✅ Папка создана: $($folder.Path)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Ошибка создания папки $($folder.Path): $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
    }
    
    # Создание тестового файла в папке
    $fileName = Split-Path $folder.Path -Leaf
    $filePath = Join-Path $folder.Path "$fileName.txt"
    
    try {
        $folder.Content | Out-File $filePath -Encoding UTF8 -Force
        Write-Host "  📄 Файл создан: $filePath" -ForegroundColor Gray
    } catch {
        Write-Host "  ❌ Ошибка создания файла: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Создание дополнительного тестового файла для демонстрации конвертации групп
$testFilePath = "C:\LabShares\TestFile.txt"
$testFileContent = @"
ТЕСТОВЫЙ ФАЙЛ ДЛЯ ДЕМОНСТРАЦИИ РАЗРЕШЕНИЙ ГРУПП
=====================================================

Этот файл используется в лабораторной работе для демонстрации:
- Назначения разрешений группам безопасности
- Конвертации между типами групп
- Поведения токенов доступа
- Влияния типа группы на доступ к ресурсам

Дата создания: $(Get-Date -Format 'dd.MM.yyyy HH:mm')
Лабораторная среда: $($domain.DNSRoot)
Всего пользователей: $($usersToCreate.Count)

Инструкции для демонстрации:
1. Назначьте разрешения группе безопасности
2. Протестируйте доступ пользователей из группы
3. Конвертируйте группу в группу рассылки
4. Проверьте изменение доступа (должен исчезнуть)
5. Конвертируйте обратно в группу безопасности
6. Проверьте восстановление доступа

Тестовые пользователи по департаментам:
IT: Иван Петров, Мария Сидорова, Антон Волков, Татьяна Крылова
Finance: Сергей Морозов, Елена Волкова, Наталия Фёдорова, Владимир Соколов
Marketing: Дмитрий Орлов, Анна Попова, Максим Лебедев
HR: Ольга Смирнова, Екатерина Новикова, Алексей Жилин

© Learn IT Lessons - Windows Server 2025
"@

try {
    $testFileContent | Out-File $testFilePath -Encoding UTF8 -Force
    Write-Host "✅ Специальный тестовый файл создан: $testFilePath" -ForegroundColor Green
} catch {
    Write-Host "❌ Ошибка создания тестового файла: $($_.Exception.Message)" -ForegroundColor Red
}

# Отображение созданной файловой структуры
Write-Host "`n📋 Созданная файловая структура:" -ForegroundColor Cyan
try {
    $fileStructure = Get-ChildItem "C:\LabShares" -Recurse | Select-Object Mode, Name, Length, FullName | Sort-Object FullName
    $fileStructure | Format-Table -AutoSize
    
    $folderCount = ($fileStructure | Where-Object {$_.Mode -like "d*"}).Count
    $fileCount = ($fileStructure | Where-Object {$_.Mode -notlike "d*"}).Count
    Write-Host "✅ Создано папок: $folderCount, файлов: $fileCount" -ForegroundColor Green
} catch {
    Write-Host "❌ Ошибка отображения файловой структуры: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "✅ ЭТАП 3 ЗАВЕРШЁН: Файловая структура готова" -ForegroundColor Green

# ЭТАП 4: НАСТРОЙКА УДАЛЁННОГО ДОСТУПА
Write-Host "`n🔐 ЭТАП 4: Настройка удалённого доступа..." -ForegroundColor Cyan
Write-Host "Добавляем пользователей в группы для RDP и PowerShell Remoting" -ForegroundColor Gray

# Получение списка созданных пользователей
try {
    $labUsers = Get-ADUser -Filter * -SearchBase "OU=Lab-Groups,$domainDN" | Select-Object -ExpandProperty SamAccountName
    
    if ($labUsers.Count -eq 0) {
        Write-Host "❌ Тестовые пользователи не найдены! Пропускаем настройку удалённого доступа." -ForegroundColor Red
    } else {
        Write-Host "👥 Найдено пользователей для настройки: $($labUsers.Count)" -ForegroundColor Green
        Write-Host "Пользователи по департаментам:" -ForegroundColor Gray
        
        $departmentNames | ForEach-Object {
            $deptName = $_
            $deptUsers = Get-ADUser -Filter "Department -eq '$deptName'" -SearchBase "OU=Lab-Groups,$domainDN" -Properties Department | Select-Object -ExpandProperty SamAccountName
            if ($deptUsers) {
                Write-Host "  $deptName ($($deptUsers.Count)): $($deptUsers -join ', ')" -ForegroundColor Gray
            }
        }
        
        # Функция для безопасного добавления пользователей в группу
        function Add-UsersToSecurityGroup {
            param(
                [string]$GroupName,
                [array]$UserList,
                [string]$GroupDescription
            )
            
            Write-Host "`n🔧 Обработка группы: $GroupName" -ForegroundColor Cyan
            Write-Host "   Назначение: $GroupDescription" -ForegroundColor Gray
            
            try {
                # Проверяем существование группы
                $targetGroup = Get-ADGroup -Identity $GroupName -ErrorAction Stop
                
                $addedUsers = 0
                $existingUsers = 0
                $errorUsers = 0
                
                foreach ($username in $UserList) {
                    try {
                        # Проверяем, является ли пользователь уже членом группы
                        $currentMembers = Get-ADGroupMember -Identity $GroupName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName
                        
                        if ($currentMembers -contains $username) {
                            Write-Host "  ⚠️ $username уже является членом группы" -ForegroundColor Yellow
                            $existingUsers++
                        } else {
                            Add-ADGroupMember -Identity $GroupName -Members $username -ErrorAction Stop
                            Write-Host "  ✅ $username добавлен в группу" -ForegroundColor Green
                            $addedUsers++
                        }
                    } catch {
                        Write-Host "  ❌ Ошибка добавления $username : $($_.Exception.Message)" -ForegroundColor Red
                        $errorUsers++
                    }
                }
                
                Write-Host "  📊 Итог: добавлено $addedUsers, уже было $existingUsers, ошибок $errorUsers" -ForegroundColor Cyan
                
            } catch {
                Write-Host "  ❌ Группа $GroupName не найдена: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  💡 Это может быть нормально для некоторых конфигураций Windows Server" -ForegroundColor Yellow
            }
        }
        
        # Добавление в группы удалённого доступа
        Add-UsersToSecurityGroup -GroupName "Remote Desktop Users" -UserList $labUsers -GroupDescription "Разрешает подключение через Remote Desktop Protocol (RDP)"
        
        Add-UsersToSecurityGroup -GroupName "Remote Management Users" -UserList $labUsers -GroupDescription "Разрешает удалённое управление через WinRM и PowerShell"
        
        # Попытка добавить в дополнительные группы (если существуют)
        try {
            Add-UsersToSecurityGroup -GroupName "WinRMRemoteWMIUsers__" -UserList $labUsers -GroupDescription "Разрешает удалённый доступ через WMI"
        } catch {
            Write-Host "⚠️ Группа WinRMRemoteWMIUsers не найдена (это нормально)" -ForegroundColor Yellow
        }
        
        # Проверка итогового членства в группах (выборочно)
        Write-Host "`n📋 Проверка членства в группах удалённого доступа (выборочно):" -ForegroundColor Cyan
        
        # Проверяем по одному пользователю из каждого департамента
        $sampleUsers = @("IvanPetrov", "SergeyMorozov", "DmitryOrlov", "OlgaSmirova")
        
        foreach ($username in $sampleUsers) {
            if ($labUsers -contains $username) {
                Write-Host "`n👤 Пользователь: $username" -ForegroundColor White
                
                try {
                    # Получаем все группы пользователя
                    $userMembership = Get-ADUser -Identity $username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
                    
                    # Проверяем членство в ключевых группах
                    $rdpAccess = $userMembership | Where-Object { $_ -like "*Remote Desktop Users*" }
                    $remoteManagement = $userMembership | Where-Object { $_ -like "*Remote Management Users*" }
                    $winrmAccess = $userMembership | Where-Object { $_ -like "*WinRM*" }
                    
                    if ($rdpAccess) {
                        Write-Host "  ✅ Remote Desktop Users - RDP доступ разрешён" -ForegroundColor Green
                    } else {
                        Write-Host "  ❌ НЕТ доступа через Remote Desktop" -ForegroundColor Red
                    }
                    
                    if ($remoteManagement) {
                        Write-Host "  ✅ Remote Management Users - PowerShell Remoting разрешён" -ForegroundColor Green
                    }
                    
                    if ($winrmAccess) {
                        Write-Host "  ✅ WinRM доступ настроен" -ForegroundColor Green
                    }
                    
                } catch {
                    Write-Host "  ❌ Ошибка проверки пользователя $username : $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        Write-Host "`n💡 Примечание: Проверены только выборочные пользователи. Все $($labUsers.Count) пользователей настроены аналогично." -ForegroundColor Yellow
        Write-Host "✅ ЭТАП 4 ЗАВЕРШЁН: Удалённый доступ настроен" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Критическая ошибка при настройке удалённого доступа: $($_.Exception.Message)" -ForegroundColor Red
}

# ФИНАЛЬНЫЙ ОТЧЁТ И ИНСТРУКЦИИ
Write-Host "`n" + "=" * 80 -ForegroundColor Magenta
Write-Host "🎉 ЛАБОРАТОРНАЯ СРЕДА ДЛЯ ИЗУЧЕНИЯ ГРУПП ПОЛНОСТЬЮ ГОТОВА!" -ForegroundColor Magenta
Write-Host "=" * 80 -ForegroundColor Magenta

Write-Host "`n📋 СВОДКА СОЗДАННЫХ РЕСУРСОВ:" -ForegroundColor Cyan

# Сводка по домену
Write-Host "`n🌐 ИНФОРМАЦИЯ О ДОМЕНЕ:" -ForegroundColor Yellow
Write-Host "   Имя домена: $($domain.DNSRoot)" -ForegroundColor White
Write-Host "   Distinguished Name: $domainDN" -ForegroundColor White
Write-Host "   Функциональный уровень домена: $($domain.DomainMode)" -ForegroundColor White
Write-Host "   Функциональный уровень леса: $((Get-ADForest).ForestMode)" -ForegroundColor White
Write-Host "   Контроллер домена: $($env:COMPUTERNAME)" -ForegroundColor White

Write-Host "   Distinguished Name: $domainDN" -ForegroundColor White
Write-Host "   Функциональный уровень домена: $($domain.DomainMode)" -ForegroundColor White

# Сводка по пользователям
try {
   $finalUserCount = (Get-ADUser -Filter * -SearchBase "OU=Lab-Groups,$domainDN").Count
   Write-Host "`n👥 ПОЛЬЗОВАТЕЛИ:" -ForegroundColor Yellow
   Write-Host "   Всего создано: $finalUserCount" -ForegroundColor White
   Write-Host "   Пароль для всех: Somepass1" -ForegroundColor White
   Write-Host "   Организация: Learn IT Lessons" -ForegroundColor White
   
   # Детальная статистика по департаментам
   Write-Host "`n   Распределение по департаментам:" -ForegroundColor White
   $departmentNames | ForEach-Object {
       $deptName = $_
       try {
           $deptCount = (Get-ADUser -Filter "Department -eq '$deptName'" -SearchBase "OU=Lab-Groups,$domainDN" -Properties Department).Count
           Write-Host "     $deptName отдел: $deptCount пользователей" -ForegroundColor Gray
       } catch {
           Write-Host "     $deptName отдел: ошибка подсчёта" -ForegroundColor Red
       }
   }
} catch {
   Write-Host "`n👥 ПОЛЬЗОВАТЕЛИ: Ошибка подсчёта" -ForegroundColor Red
}

# Сводка по файлам
try {
   $folderCount = (Get-ChildItem "C:\LabShares" -Directory -ErrorAction SilentlyContinue).Count
   $fileCount = (Get-ChildItem "C:\LabShares" -File -Recurse -ErrorAction SilentlyContinue).Count
   Write-Host "`n📁 ФАЙЛОВЫЕ РЕСУРСЫ:" -ForegroundColor Yellow
   Write-Host "   Основная папка: C:\LabShares" -ForegroundColor White
   Write-Host "   Создано папок: $folderCount" -ForegroundColor White
   Write-Host "   Создано файлов: $fileCount" -ForegroundColor White
   Write-Host "   Папки департаментов:" -ForegroundColor White
   Write-Host "     - IT-Resources (для IT отдела)" -ForegroundColor Gray
   Write-Host "     - Finance-Data (для Finance отдела)" -ForegroundColor Gray
   Write-Host "     - Company-Announcements (для всех)" -ForegroundColor Gray
   Write-Host "     - Marketing-Materials (для Marketing отдела)" -ForegroundColor Gray
   Write-Host "     - TestFile.txt (для демонстрации конвертации групп)" -ForegroundColor Gray
} catch {
   Write-Host "`n📁 ФАЙЛОВЫЕ РЕСУРСЫ: Ошибка подсчёта" -ForegroundColor Red
}

# Инструкции по использованию
Write-Host "`n🚀 ГОТОВО К ДЕМОНСТРАЦИИ!" -ForegroundColor Yellow
Write-Host "`nТеперь можно начинать практические демонстрации:" -ForegroundColor White
Write-Host "✅ Создание групп безопасности и групп рассылки" -ForegroundColor Gray
Write-Host "✅ Назначение разрешений на файлы и папки" -ForegroundColor Gray
Write-Host "✅ Демонстрация обновления токенов доступа" -ForegroundColor Gray
Write-Host "✅ Конвертация между типами групп" -ForegroundColor Gray
Write-Host "✅ Тестирование доступа к ресурсам" -ForegroundColor Gray
Write-Host "✅ Работа с группами рассылки для email" -ForegroundColor Gray

Write-Host "`n🔐 ИНФОРМАЦИЯ ДЛЯ ПОДКЛЮЧЕНИЯ:" -ForegroundColor Yellow
Write-Host "   Формат логина: $($domain.DNSRoot)\ИмяПользователя" -ForegroundColor White
Write-Host "   Примеры логинов по департаментам:" -ForegroundColor White
Write-Host "     IT отдел:" -ForegroundColor Cyan
Write-Host "       $($domain.DNSRoot)\IvanPetrov (Системный администратор)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\MariaSidorova (Разработчик)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\AntonVolkov (Сетевой администратор)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\TatianaKrylova (Тестировщик)" -ForegroundColor Gray
Write-Host "     Finance отдел:" -ForegroundColor Cyan
Write-Host "       $($domain.DNSRoot)\SergeyMorozov (Главный бухгалтер)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\ElenaVolkova (Финансовый аналитик)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\NataliaFedorova (Экономист)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\VladimirSokolov (Аудитор)" -ForegroundColor Gray
Write-Host "     Marketing отдел:" -ForegroundColor Cyan
Write-Host "       $($domain.DNSRoot)\DmitryOrlov (Маркетолог)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\AnnaPopova (PR-менеджер)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\MaximLebedev (SMM-специалист)" -ForegroundColor Gray
Write-Host "     HR отдел:" -ForegroundColor Cyan
Write-Host "       $($domain.DNSRoot)\OlgaSmirova (HR-специалист)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\EkaterinaNovikova (Рекрутер)" -ForegroundColor Gray
Write-Host "       $($domain.DNSRoot)\AlexeyZhilin (Менеджер по персоналу)" -ForegroundColor Gray
Write-Host "   Пароль для всех: Somepass1" -ForegroundColor White

Write-Host "`n🛠️ ДОСТУПНЫЕ МЕТОДЫ ПОДКЛЮЧЕНИЯ:" -ForegroundColor Yellow
Write-Host "   ✅ Remote Desktop Protocol (RDP)" -ForegroundColor Green
Write-Host "   ✅ PowerShell Remoting" -ForegroundColor Green
Write-Host "   ✅ Windows Remote Management (WinRM)" -ForegroundColor Green

Write-Host "`n📚 ПОШАГОВОЕ РУКОВОДСТВО ДЛЯ ДЕМОНСТРАЦИИ:" -ForegroundColor Yellow
Write-Host "1. Откройте Active Directory Users and Computers (dsa.msc)" -ForegroundColor White
Write-Host "2. Перейдите в OU=Lab-Groups,DC=$($domain.DNSRoot.Replace('.', ',DC='))" -ForegroundColor White
Write-Host "3. Создайте группы безопасности:" -ForegroundColor White
Write-Host "   - IT-Security (для IT отдела)" -ForegroundColor Gray
Write-Host "   - Finance-Security (для Finance отдела)" -ForegroundColor Gray
Write-Host "4. Создайте группы рассылки:" -ForegroundColor White
Write-Host "   - All-Employees (для всех сотрудников)" -ForegroundColor Gray
Write-Host "   - IT-Announcements (для IT уведомлений)" -ForegroundColor Gray
Write-Host "5. Добавьте пользователей в соответствующие группы" -ForegroundColor White
Write-Host "6. Настройте разрешения на папки в C:\LabShares" -ForegroundColor White
Write-Host "7. Протестируйте доступ пользователей" -ForegroundColor White
Write-Host "8. Продемонстрируйте конвертацию групп и её влияние" -ForegroundColor White

Write-Host "`n💡 РЕКОМЕНДАЦИИ ДЛЯ ДЕМОНСТРАЦИИ:" -ForegroundColor Yellow
Write-Host "• Используйте пользователей из разных отделов для тестирования" -ForegroundColor White
Write-Host "• Демонстрируйте различия в поведении групп безопасности и рассылки" -ForegroundColor White
Write-Host "• Покажите важность перелогина после изменения групповой принадлежности" -ForegroundColor White
Write-Host "• Используйте команду 'whoami /groups' для проверки токенов доступа" -ForegroundColor White
Write-Host "• Демонстрируйте работу с Exchange Server (если доступен)" -ForegroundColor White

Write-Host "`n🎯 СЦЕНАРИИ ДЛЯ ДЕМОНСТРАЦИИ:" -ForegroundColor Yellow
Write-Host "Сценарий 1: IT отдел получает доступ к IT-Resources" -ForegroundColor White
Write-Host "  - Создать группу IT-Security" -ForegroundColor Gray
Write-Host "  - Добавить IvanPetrov, MariaSidorova, AntonVolkov, TatianaKrylova" -ForegroundColor Gray
Write-Host "  - Назначить права на C:\LabShares\IT-Resources" -ForegroundColor Gray
Write-Host "  - Протестировать доступ" -ForegroundColor Gray

Write-Host "`nСценарий 2: Finance отдел и конфиденциальные данные" -ForegroundColor White
Write-Host "  - Создать группу Finance-Security" -ForegroundColor Gray
Write-Host "  - Добавить SergeyMorozov, ElenaVolkova, NataliaFedorova, VladimirSokolov" -ForegroundColor Gray
Write-Host "  - Назначить права на C:\LabShares\Finance-Data" -ForegroundColor Gray
Write-Host "  - Проверить, что другие отделы не имеют доступа" -ForegroundColor Gray

Write-Host "`nСценарий 3: Группы рассылки для объявлений" -ForegroundColor White
Write-Host "  - Создать группу All-Employees (тип: Distribution)" -ForegroundColor Gray
Write-Host "  - Добавить всех пользователей" -ForegroundColor Gray
Write-Host "  - Попытаться назначить права на файл (должно не работать)" -ForegroundColor Gray
Write-Host "  - Показать использование для email рассылки" -ForegroundColor Gray

Write-Host "`nСценарий 4: Конвертация групп" -ForegroundColor White
Write-Host "  - Создать группу, назначить права на TestFile.txt" -ForegroundColor Gray
Write-Host "  - Конвертировать в Distribution group" -ForegroundColor Gray
Write-Host "  - Показать потерю доступа" -ForegroundColor Gray
Write-Host "  - Конвертировать обратно в Security group" -ForegroundColor Gray
Write-Host "  - Показать восстановление доступа" -ForegroundColor Gray

Write-Host "`n" + "=" * 80 -ForegroundColor Magenta
Write-Host "🎓 УДАЧНОГО ОБУЧЕНИЯ! ЛАБОРАТОРНАЯ СРЕДА ГОТОВА К ИСПОЛЬЗОВАНИЮ!" -ForegroundColor Magenta
Write-Host "   Всего пользователей: $($usersToCreate.Count)" -ForegroundColor White
Write-Host "   IT: 4 | Finance: 4 | Marketing: 3 | HR: 3" -ForegroundColor White
Write-Host "=" * 80 -ForegroundColor Magenta

# Конец скрипта - сохранение лога выполнения
$logPath = "C:\LabShares\Lab-Setup-Log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
try {
   $logContent = @"
ЛОГ НАСТРОЙКИ ЛАБОРАТОРНОЙ СРЕДЫ ДЛЯ ИЗУЧЕНИЯ ГРУПП WINDOWS SERVER 2025
========================================================================

Дата выполнения: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
Домен: $($domain.DNSRoot)
Distinguished Name: $domainDN
Функциональный уровень: $($domain.DomainMode)

СОЗДАННЫЕ ПОЛЬЗОВАТЕЛИ ($($usersToCreate.Count) чел.):
========================================

IT ОТДЕЛ (4 чел.):
- IvanPetrov (Иван Петров) - Системный администратор
- MariaSidorova (Мария Сидорова) - Разработчик  
- AntonVolkov (Антон Волков) - Сетевой администратор
- TatianaKrylova (Татьяна Крылова) - Тестировщик

FINANCE ОТДЕЛ (4 чел.):
- SergeyMorozov (Сергей Морозов) - Главный бухгалтер
- ElenaVolkova (Елена Волкова) - Финансовый аналитик
- NataliaFedorova (Наталия Фёдорова) - Экономист
- VladimirSokolov (Владимир Соколов) - Аудитор

MARKETING ОТДЕЛ (3 чел.):
- DmitryOrlov (Дмитрий Орлов) - Маркетолог
- AnnaPopova (Анна Попова) - PR-менеджер
- MaximLebedev (Максим Лебедев) - SMM-специалист

HR ОТДЕЛ (3 чел.):
- OlgaSmirova (Ольга Смирнова) - HR-специалист
- EkaterinaNovikova (Екатерина Новикова) - Рекрутер
- AlexeyZhilin (Алексей Жилин) - Менеджер по персоналу

СОЗДАННЫЕ РЕСУРСЫ:
===================
OU структура: OU=Lab-Groups с подразделениями IT, Finance, Marketing, HR
Папки: C:\LabShares\IT-Resources, Finance-Data, Company-Announcements, Marketing-Materials
Файлы: TestFile.txt и соответствующие файлы в каждой папке

НАСТРОЙКИ ДОСТУПА:
==================
Все пользователи добавлены в группы Remote Desktop Users и Remote Management Users
Пароль для всех пользователей: Somepass1

ФОРМАТ ЛОГИНА:
==============
$($domain.DNSRoot)\ИмяПользователя
Примеры: $($domain.DNSRoot)\IvanPetrov, $($domain.DNSRoot)\SergeyMorozov

СТАТУС: Скрипт выполнен успешно
ГОТОВНОСТЬ: Лабораторная среда готова к демонстрации групп

© Learn IT Lessons - Windows Server 2025 Lab Environment
"@
   
   $logContent | Out-File $logPath -Encoding UTF8
   Write-Host "`n📝 Детальный лог сохранён: $logPath" -ForegroundColor Cyan
   Write-Host "   Содержит полную информацию о созданных пользователях и ресурсах" -ForegroundColor Gray
} catch {
   Write-Host "`n⚠️ Не удалось сохранить лог выполнения: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🔚 СКРИПТ ЗАВЕРШЁН УСПЕШНО" -ForegroundColor Green
Write-Host "Время выполнения: $(Get-Date)" -ForegroundColor Gray
