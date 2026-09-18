## Automated Installation of Essential Software

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\autoinstall.ps1"
```

Installs via WinGet:
- WinRAR with a German interface
- Google Chrome
- Adobe Acrobat Reader
- AnyDesk

The block also includes 7-Zip, VLC, and Notepad++ — comment out or remove the corresponding lines in the `$packages` array if needed. WinGet supports silent package installation and the `--locale de-DE` localization parameter.

***

## Автоустановка базовых программ

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\autoinstall.ps1
```

Устанавливает через WinGet:
- WinRAR с немецким интерфейсом
- Google Chrome
- Adobe Acrobat Reader
- AnyDesk.

В блок также добавлены 7-Zip, VLC и Notepad++ — при необходимости закомментируйте или удалите соответствующие строки в массиве $packages. WinGet поддерживает автоматическую установку пакетов и параметр локали --locale de-DE
