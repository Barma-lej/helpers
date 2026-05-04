# users_login_log

> 🇷🇺 [Русский](#русский) | 🇬🇧 [English](#english)

---

## English

### Description

A PowerShell script that logs RDP/RDS user session events to a CSV file. It is triggered by Windows Task Scheduler on specific Event Log events — successful logins, disconnects, logoffs, and failed login attempts — and appends a structured record to the log file each time.

### Features

- Captures RDP session events: login (`Anmeldung`), reconnect (`Anmeldung (Rec)`), disconnect (`Trennung`), logoff (`Abmeldung`)
- Captures failed login attempts (`FEHLER (Logon)`) from the Security log (Event ID 4625)
- Logs username, IP address, session ID (for successful events) or PC name (for failed attempts)
- Writes structured records to a CSV file (`Data;Zeit;Ereigniss;Name`)
- Creates the CSV file automatically if it does not exist
- Triggered by Windows Task Scheduler — no polling, event-driven
- Exits cleanly if no relevant event occurred within the last 15 seconds

### Files

| File | Description |
|------|-------------|
| `users_log.ps1` | Main PowerShell script |
| `TaskPlanner_User_Reconnect.xml` | Task Scheduler import file |

### CSV Log Format

The log is saved to `C:\_Scripts\users_login.csv` by default.

| Column | Description |
|--------|-------------|
| `Data` | Date in `dd.MM.yyyy` format |
| `Zeit` | Time in `HH:mm:ss` format |
| `Ereigniss` | Event type (see table below) |
| `Name` | Username with IP, session ID or PC name |

### Event Types

| Event ID | Source Log | `Ereigniss` value | Description |
|----------|------------|-------------------|-------------|
| 21 | TerminalServices | `Anmeldung` | First/new login |
| 25 | TerminalServices | `Anmeldung (Rec)` | Reconnect after disconnect |
| 24 | TerminalServices | `Trennung` | Session disconnected (window closed) |
| 23 | TerminalServices | `Abmeldung` | User logged off |
| 4625 | Security | `FEHLER (Logon)` | Failed login attempt |

### Requirements

- Windows Server with Remote Desktop Services (RDS) / RDP enabled
- PowerShell 5.1 or later
- **SYSTEM** account privileges (the Task Scheduler task runs as `S-1-5-18`)
- Security Auditing enabled for failed logon events (Event ID 4625)

### Usage

**Run manually from PowerShell (for testing):**

```powershell
.\users_log.ps1
```

> Note: Running manually will likely exit immediately unless a relevant event occurred in the last 15 seconds.

**Path to the log file** (hardcoded, change in the script if needed):

```
C:\_Scripts\users_login.csv
```

### Task Scheduler Setup

1. Open **Task Scheduler** (`taskschd.msc`)
2. Click **Import Task...**
3. Select `TaskPlanner_User_Reconnect.xml`
4. Adjust the path to the script (`C:\_Scripts\users_log.ps1`) if needed
5. The task runs as **SYSTEM** (`S-1-5-18`) — no password required

The task is triggered by two event sources:
- `Microsoft-Windows-TerminalServices-LocalSessionManager/Operational` — Event IDs **21, 23, 24, 25**
- `Security` — Event ID **4625** (failed logon)

### How It Works

1. Task Scheduler triggers the script when a relevant event fires
2. The script reads the last 10 events from `TerminalServices-LocalSessionManager/Operational` and checks for events within the last 15 seconds
3. It also checks the `Security` log for failed logins (Event ID 4625) within the last 15 seconds
4. Failed login events take priority if they occurred more recently than a terminal services event
5. The event type, username, IP address, and session details are appended to the CSV file
6. If no matching event is found within 15 seconds, the script exits without writing anything

---

## Русский

### Описание

PowerShell-скрипт для ведения журнала RDP/RDS-сессий пользователей в CSV-файл. Запускается через Планировщик задач Windows по событиям журнала событий: успешные входы, отключения, выходы из системы, а также неудачные попытки входа. При каждом событии в файл добавляется структурированная запись.

### Возможности

- Фиксирует RDP-события: вход (`Anmeldung`), повторное подключение (`Anmeldung (Rec)`), отключение (`Trennung`), выход (`Abmeldung`)
- Фиксирует неудачные попытки входа (`FEHLER (Logon)`) из журнала Security (Event ID 4625)
- Записывает имя пользователя, IP-адрес, ID сессии (для успешных событий) или имя PC (для неудачных)
- Записывает данные в CSV-файл с заголовком `Data;Zeit;Ereigniss;Name`
- Автоматически создаёт CSV-файл, если он не существует
- Запускается через Планировщик задач по событию — без поллинга
- Завершается без записи, если за последние 15 секунд ничего не произошло

### Файлы

| Файл | Описание |
|------|----------|
| `users_log.ps1` | Основной PowerShell-скрипт |
| `TaskPlanner_User_Reconnect.xml` | Файл импорта задачи для Планировщика задач |

### Формат CSV-журнала

Журнал по умолчанию сохраняется в `C:\_Scripts\users_login.csv`.

| Колонка | Описание |
|---------|----------|
| `Data` | Дата в формате `dd.MM.yyyy` |
| `Zeit` | Время в формате `HH:mm:ss` |
| `Ereigniss` | Тип события (см. таблицу ниже) |
| `Name` | Имя пользователя, IP-адрес, ID сессии или имя PC |

### Типы событий

| Event ID | Журнал | Значение `Ereigniss` | Описание |
|----------|--------|----------------------|----------|
| 21 | TerminalServices | `Anmeldung` | Первый/новый вход |
| 25 | TerminalServices | `Anmeldung (Rec)` | Повторное подключение после отключения |
| 24 | TerminalServices | `Trennung` | Отключение (закрытие окна) |
| 23 | TerminalServices | `Abmeldung` | Выход из системы |
| 4625 | Security | `FEHLER (Logon)` | Неудачная попытка входа |

### Требования

- Windows Server с включённым Remote Desktop Services (RDS) / RDP
- PowerShell 5.1 или новее
- Задача выполняется от имени **SYSTEM** (`S-1-5-18`) — пароль не нужен
- Включённый аудит безопасности для неудачных попыток входа (Event ID 4625)

### Использование

**Запуск вручную для тестирования:**

```powershell
.\users_log.ps1
```

> Примечание: при запуске вручную скрипт, скорее всего, сразу завершится без записи, если за последние 15 секунд не было событий.

**Путь к журнальному файлу** (прописан в скрипте, измените при необходимости):

```
C:\_Scripts\users_login.csv
```

### Настройка Планирощика задач

1. Откройте **Планировщик задач** (`taskschd.msc`)
2. Нажмите **Импортировать задачу...**
3. Выберите файл `TaskPlanner_User_Reconnect.xml`
4. Проверьте путь к скрипту (`C:\_Scripts\users_log.ps1`) и при необходимости скорректируйте
5. Задача выполняется от имени **SYSTEM** (`S-1-5-18`) — пароль не требуется

Задача запускается по двум источникам событий:
- `Microsoft-Windows-TerminalServices-LocalSessionManager/Operational` — Event ID **21, 23, 24, 25**
- `Security` — Event ID **4625** (неудачная авторизация)

### Принцип работы

1. Планировщик задач запускает скрипт при появлении нужного события
2. Скрипт читает последние 10 событий из `TerminalServices-LocalSessionManager/Operational` и фильтрует события за последние 15 секунд
3. Параллельно проверяется журнал `Security` на наличие Event ID 4625 за последние 15 секунд
4. Событие неудачной авторизации имеет приоритет, если оно произошло позже события TerminalServices
5. Тип события, имя пользователя, IP-адрес и дополнительные данные записываются в CSV
6. Если за 15 секунд нет подходящих событий, скрипт завершается без записи

---

*© [Barma-lej](https://github.com/Barma-lej/tools/tree/main/users_login_log)*
