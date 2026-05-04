# Protect-RDSFromBruteforce

> 🇷🇺 [Русский](#русский) | 🇬🇧 [English](#english)

---

## English

### Description

A PowerShell script that monitors Windows Event Log for failed RDP login attempts and automatically creates Windows Firewall block rules for offending IP addresses. Block rules are automatically removed after a configurable time period. Optionally generates a styled HTML report.

### Features

- Reads failed RDP connection events from `Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational` log (Event ID 140)
- Automatically blocks IPs that exceed the failed login threshold
- Automatically removes expired block rules after a defined time
- Resolves IP geolocation (country) via [ip-api.com](http://ip-api.com)
- Generates a styled HTML report with offending IPs and current firewall rules
- Can be scheduled via Windows Task Scheduler

### Files

| File | Description |
|------|-------------|
| `Protect-RDSFromBruteforce.ps1` | Main PowerShell script |
| `TaskPlanner_Protect-RDSFromBruteforce.xml` | Task Scheduler import file |

### Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `timePeriod` | `60` | 1–1440 | How far back (in minutes) to look in the event log |
| `FailedLoginCount` | `5` | 1–100 | Minimum failed attempts to trigger a block |
| `RemoveBlockRuleAfter` | `1440` | 1–10080 | Minutes before the block rule is removed |
| `HTMLReportPath` | `c:\_Scripts\BruteForceReport.html` | — | Path for the HTML report (leave empty to skip) |

### Requirements

- Windows Server with Remote Desktop Services (RDS) / RDP enabled
- PowerShell 5.1 or later
- Administrator privileges (required to manage firewall rules)
- Internet access for IP geolocation (optional, gracefully falls back to "Unknown")

### Usage

**Run manually from PowerShell:**

```powershell
.\Protect-RDSFromBruteforce.ps1
```

**Run with custom parameters:**

```powershell
.\Protect-RDSFromBruteforce.ps1 -FailedLoginCount 10 -timePeriod 30 -RemoveBlockRuleAfter 720
```

**Run from Task Scheduler:**

```cmd
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -file "C:\Shares\Scripts\Protect-RDSFromBruteforce\Protect-RDSFromBruteforce.ps1" -FailedLoginCount 10
```

### Task Scheduler Setup

1. Open **Task Scheduler** (`taskschd.msc`)
2. Click **Import Task...**
3. Select `TaskPlanner_Protect-RDSFromBruteforce.xml`
4. Adjust the script path and parameters as needed
5. Ensure the task runs under an account with **Administrator** privileges

### How It Works

1. The script queries the Windows Event Log for RDP failure events (EventID 140) within the defined `timePeriod`
2. It groups events by IP address and filters those that exceed `FailedLoginCount`
3. New firewall block rules (`RDP-BruteForce-Block`) are created for offending IPs not yet blocked
4. Existing rules older than `RemoveBlockRuleAfter` minutes are automatically deleted
5. An HTML report is generated at `HTMLReportPath` (if specified)

### HTML Report

The report includes:
- **Current Offending IPs** — IP, country, number of attempts, time between first and last attempt
- **Firewall Rules Block List** — all current block rules with timestamps and expiration status

---

## Русский

### Описание

PowerShell-скрипт для защиты RDP/RDS от брутфорс-атак. Скрипт анализирует журнал событий Windows на предмет неудачных попыток подключения по RDP и автоматически создаёт правила брандмауэра для блокировки атакующих IP-адресов. По истечении заданного времени правила автоматически удаляются. По желанию формируется стилизованный HTML-отчёт.

### Возможности

- Читает события неудачных подключений RDP из журнала `Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational` (Event ID 140)
- Автоматически блокирует IP-адреса, превысившие порог неудачных попыток входа
- Автоматически удаляет устаревшие правила блокировки по истечении заданного времени
- Определяет страну по IP-адресу через [ip-api.com](http://ip-api.com)
- Генерирует стилизованный HTML-отчёт с атакующими IP и текущими правилами брандмауэра
- Поддерживает запуск через Планировщик задач Windows

### Файлы

| Файл | Описание |
|------|----------|
| `Protect-RDSFromBruteforce.ps1` | Основной PowerShell-скрипт |
| `TaskPlanner_Protect-RDSFromBruteforce.xml` | Файл импорта задачи для Планировщика задач |

### Параметры

| Параметр | По умолчанию | Диапазон | Описание |
|----------|--------------|----------|----------|
| `timePeriod` | `60` | 1–1440 | Глубина анализа журнала событий (в минутах) |
| `FailedLoginCount` | `5` | 1–100 | Минимальное число неудачных попыток для блокировки IP |
| `RemoveBlockRuleAfter` | `1440` | 1–10080 | Через сколько минут правило блокировки будет удалено |
| `HTMLReportPath` | `c:\_Scripts\BruteForceReport.html` | — | Путь к HTML-отчёту (оставьте пустым, чтобы не создавать) |

### Требования

- Windows Server с включённым Remote Desktop Services (RDS) / RDP
- PowerShell 5.1 или новее
- Права администратора (необходимы для управления правилами брандмауэра)
- Доступ в интернет для определения геолокации IP (опционально, при ошибке возвращается "Unknown")

### Использование

**Запуск вручную из PowerShell:**

```powershell
.\Protect-RDSFromBruteforce.ps1
```

**Запуск с пользовательскими параметрами:**

```powershell
.\Protect-RDSFromBruteforce.ps1 -FailedLoginCount 10 -timePeriod 30 -RemoveBlockRuleAfter 720
```

**Запуск из Планировщика задач:**

```cmd
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -file "C:\Shares\Scripts\Protect-RDSFromBruteforce\Protect-RDSFromBruteforce.ps1" -FailedLoginCount 10
```

### Настройка Планировщика задач

1. Откройте **Планировщик задач** (`taskschd.msc`)
2. Нажмите **Импортировать задачу...**
3. Выберите файл `TaskPlanner_Protect-RDSFromBruteforce.xml`
4. Скорректируйте путь к скрипту и параметры по необходимости
5. Убедитесь, что задача выполняется от имени учётной записи с правами **Администратора**

### Принцип работы

1. Скрипт запрашивает журнал событий Windows на наличие событий отказа RDP (EventID 140) за период `timePeriod`
2. События группируются по IP-адресу; отбираются IP, превысившие `FailedLoginCount`
3. Для ещё не заблокированных IP создаются правила брандмауэра (`RDP-BruteForce-Block`)
4. Существующие правила, созданные более `RemoveBlockRuleAfter` минут назад, автоматически удаляются
5. Если указан `HTMLReportPath`, создаётся HTML-отчёт

### HTML-отчёт

Отчёт содержит:
- **Текущие атакующие IP** — IP, страна, количество попыток, время между первой и последней попыткой
- **Список правил блокировки брандмауэра** — все активные правила с временными метками и статусом истечения

---

*© [Barma-lej](https://github.com/Barma-lej/tools/tree/main/Protect-RDSFromBruteforce)*
