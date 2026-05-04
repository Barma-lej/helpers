$MyPath = "C:\_Scripts\users_login.csv"
$Date = Get-Date -Format "dd.MM.yyyy"
$Time = Get-Date -Format "HH:mm:ss"

# 1. Проверяем журнал терминалов (Успешные действия: 21, 23, 24, 25)
$TermEvent = Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" -MaxEvents 10 -ErrorAction SilentlyContinue | 
             Where-Object { $_.Id -in 21, 23, 24, 25 -and $_.TimeCreated -ge (Get-Date).AddSeconds(-15) } | 
             Select-Object -First 1

# 2. Проверяем журнал Security (Неудачные попытки - ID 4625)
# Исправлено: LogName теперь только внутри FilterHashtable
$FailEvent = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4625
    StartTime = (Get-Date).AddSeconds(-15)
} -MaxEvents 1 -ErrorAction SilentlyContinue

# 3. Логика определения события
if ($FailEvent -and (!$TermEvent -or $FailEvent.TimeCreated -gt $TermEvent.TimeCreated)) {
    $Event = "FEHLER (Logon)"
    $User = $FailEvent.Properties[5].Value  # Имя пользователя
    $IP = $FailEvent.Properties[19].Value   # IP-адрес
    $PC = $FailEvent.Properties[13].Value   # PC-Name
    $User = "$User (IP: $IP; $PC)"
} 
elseif ($TermEvent) {
    $User = $TermEvent.Properties[0].Value  # Имя пользователя
    $ID = $TermEvent.Properties[1].Value    # Номер сессии
    $IP = $TermEvent.Properties[2].Value    # IP-адрес
    $User = "$User (IP: $IP; ID: $ID)"
	
    switch ($TermEvent.Id) {
		21 { $Event = "Anmeldung" }           # Первый вход
		25 { $Event = "Anmeldung (Rec)" }     # Возврат после Trennung
		42 { $Event = "Anmeldung (Rec)" }     # Технический возврат (Arbitration)
		24 { $Event = "Trennung" }            # Закрыл крестиком
		23 { $Event = "Abmeldung" }           # Нажал Выход
        default {$Event = "ID-$($LastLog.Id)"}
    }
}
else {
    # Если за 15 сек ничего не произошло, просто выходим
    exit 
}

# 4. Запись в CSV
if (-Not (Test-Path $MyPath)) {
    "Data;Zeit;Ereigniss;Name" | Out-File $MyPath -Encoding UTF8
}

"$Date;$Time;$Event;$User" | Out-File $MyPath -Encoding UTF8 -Append
