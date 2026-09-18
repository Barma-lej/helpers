## Removing Acer Utilities

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\acer.ps1"
```

Removes:
- Acer Configuration Manager
- Jumpstart
- Care Center
- Quick Access
- The User Experience Improvement Program telemetry service

The script locates programs using standard uninstaller registry entries and avoids `Win32_Product`, which can trigger MSI package self-repair.

***

## Удаление утилит Acer

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\acer.ps1"
```

Удаляет:
- Acer Configuration Manager
- Jumpstart
- Care Center
- Quick Access
- службу телеметрии User Experience Improvement Program.

Скрипт ищет программы через записи штатного деинсталлятора и не использует Win32_Product, который может запускать восстановление MSI-пакетов.
