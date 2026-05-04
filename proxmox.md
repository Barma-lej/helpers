# Установка на NUC

Скачать:
* [Proxmox](https://www.proxmox.com/en/downloads)
* [rufus](https://rufus.ie/)

Создать загрузочную USB-флешку с помощью rufus, **выбрать DD как метод записи**

## Разделы после установки

|     Устройство     |  Начало  |   Конец   |  Секторы  | Размер |       Тип        |
|:------------------:|:--------:|:---------:|:---------:|:------:|:----------------:|
| /dev/nvme0n1p1     | 34       | 2047      | 2014      | 1007K  | BIOS boot        |
| /dev/nvme0n1p2     | 2048     | 1050623   | 1048576   | 512M   | EFI System       |
| /dev/nvme0n1p3     | 1050624  | 976773134 | 975722511 | 465.3G | Linux LVM        |
| /dev/sda1          | 2048     | 976773134 | 976771087 | 465.8G | Linux filesystem |

## Настройка

### Удалить enterprise-подписку

```bash
rm -f /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
```

### Обновить систему и установить mc

```bash
apt update && apt full-upgrade -y && apt install mc -y
```

### Установить `nano` редактором по умолчанию

```bash
update-alternatives --config editor
```

---

## Работа с дисками

### Разметка диска

```bash
ls -l /dev | grep nvme
ls -l /dev | grep sd
```

```bash
fdisk /dev/sda
d
g
n
w
```

```
Welcome to fdisk (util-linux 2.33.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): d
Selected partition 1
Partition 1 has been deleted.

Command (m for help): g
Created a new GPT disklabel (GUID: AC5BFD0E-C5D5-DF47-AA89-18D4D9138065).

Command (m for help): n
Partition number (1-128, default 1):
First sector (2048-976773134, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-976773134, default 976773134):

Created a new partition 1 of type 'Linux filesystem' and of size 465.8 GiB.
Partition #1 contains a ext4 signature.

Do you want to remove the signature? [Y]es/[N]o: y

The signature will be removed by a write command.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

### Добавить HDD-диск в Proxmox

```bash
lsblk
```

```
NAME               MAJ:MIN  RM    SIZE  RO  TYPE  MOUNTPOINT
sda                  8:0     0  465.8G   0  disk
└─sda1               8:1     0  465.8G   0  part
  └─hdd-root       253:5     0    300G   0  lvm   /mnt/root
nvme0n1            259:0     0  465.8G   0  disk
├─nvme0n1p1        259:1     0   1007K   0  part
├─nvme0n1p2        259:2     0    512M   0  part  /boot/efi
└─nvme0n1p3        259:3     0  465.3G   0  part
  ├─pve-swap       253:0     0      8G   0  lvm   [SWAP]
  ├─pve-root       253:1     0     96G   0  lvm   /
  ├─pve-data_tmeta 253:2     0    3.5G   0  lvm
  │ └─pve-data     253:4     0  338.4G   0  lvm
  └─pve-data_tdata 253:3     0  338.4G   0  lvm
    └─pve-data     253:4     0  338.4G   0  lvm
```

Создать физический том:

```bash
pvcreate /dev/sda1
```

Создать группу томов **hdd**:

```bash
vgcreate hdd /dev/sda1
```

Создать логический том (450G) в **hdd** для бэкапов, ISO-образов и т.д.:

```bash
lvcreate -L 450G -n root hdd
mkfs.ext4 -L hdd-root /dev/hdd/root
```

Создать точку монтирования:

```bash
mkdir -p /mnt/root
```

Отредактировать `/etc/fstab` и добавить запись:

```bash
nano /etc/fstab
```

```
/dev/hdd/root /mnt/root ext4 errors=remount-ro 0 1
```

Смонтировать логический том:

```bash
mount -a
```

#### Создать Directory Storage

**Datacenter → Storage → Add → Directory**

| Поле      | Значение   |
|-----------|------------|
| ID        | hdd-root   |
| Directory | /mnt/root  |

---

## Полезные команды

> Справка: [Основы LVM и команды](https://dannyda.com/2020/05/10/how-to-delete-remove-local-lvm-from-proxmox-ve-pve-and-some-lvm-basics-commands/)

### Управление виртуальными машинами

```bash
# Список всех ВМ
qm list

# Запуск / остановка / перезагрузка / выключение
qm start <vmid>
qm stop <vmid>
qm reboot <vmid>
qm shutdown <vmid>

# Статус и конфигурация ВМ
qm status <vmid>
qm config <vmid>

# Удалить ВМ
qm destroy <vmid>

# Снапшоты
qm snapshot <vmid> <имя>
qm rollback <vmid> <имя>
qm listsnapshot <vmid>

# Открыть терминал ВМ
qm terminal <vmid>
```

### Разблокировать заблокированную ВМ

```bash
rm -f /var/lock/qemu-server/lock-101.conf
qm unlock 100
qm stop 100
```

### Принудительно завершить процесс ВМ

```bash
ps aux | grep "/usr/bin/kvm -id <VID>"
kill -9 <PID>
```

### Управление контейнерами (LXC)

```bash
# Список всех контейнеров
pct list

# Запуск / остановка / перезагрузка
pct start <ctid>
pct stop <ctid>
pct reboot <ctid>

# Войти в оболочку контейнера
pct enter <ctid>

# Конфигурация и снапшоты
pct config <ctid>
pct snapshot <ctid> <имя>
pct rollback <ctid> <имя>
```

### Информация о дисках и LVM

> **pv** = физический том · **vg** = группа томов · **lv** = логический том

```bash
# Все блочные устройства
lsblk

# Подробная информация
pvdisplay /dev/nvme0n1p3
vgdisplay hdd
lvdisplay /dev/pve/root
lvdisplay /dev/hdd/root

# Краткая сводка
pvs
vgs
lvs
```

### Хранилища

```bash
# Список хранилищ и их статус
pvesm status

# Содержимое хранилища
pvesm list <storage>

# Увеличить диск ВМ
qm resize <vmid> <disk> +10G
```

### Резервное копирование и восстановление

```bash
# Создать бэкап ВМ
vzdump <vmid> --storage <storage> --mode snapshot --compress zstd

# Восстановить ВМ
qmrestore /var/lib/vz/dump/<backup.vma.zst> <vmid>

# Восстановить контейнер
pct restore <ctid> /var/lib/vz/dump/<backup.tar.zst>
```

### Сеть

```bash
# Перезагрузить сетевые интерфейсы
ifreload -a

# Показать интерфейсы
ip a

# Мониторинг трафика
iftop -i vmbr0
```

### Логи и мониторинг

```bash
# Логи служб PVE
journalctl -u pveproxy -f
journalctl -u pvedaemon -f

# Статус ресурсов ноды
pvesh get /nodes/<nodename>/status

# Статус кластера
pvecm status
pvecm nodes
```
