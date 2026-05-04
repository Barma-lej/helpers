# Install on NUC

Download:
* [Proxmox](https://www.proxmox.com/en/downloads)
* [rufus](https://rufus.ie/)

Create bootable USB-Stick with rufus, **choose DD as a write method**

## Partitions after installation

|     Device     |  Start  |    End    |  Sectors  |  Size  |       Type       |
|:--------------:|:-------:|:---------:|:---------:|:------:|:----------------:|
| /dev/nvme0n1p1 | 34      | 2047      | 2014      | 1007K  | BIOS boot        |
| /dev/nvme0n1p2 | 2048    | 1050623   | 1048576   | 512M   | EFI System       |
| /dev/nvme0n1p3 | 1050624 | 976773134 | 975722511 | 465.3G | Linux LVM        |
| /dev/sda1      | 2048    | 976773134 | 976771087 | 465.8G | Linux filesystem |

## Configuration

### Remove enterprise subscription

```bash
rm -f /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
```

### Update and install mc

```bash
apt update && apt full-upgrade -y && apt install mc -y
```

### Set `nano` as default editor

```bash
update-alternatives --config editor
```

---

## Disk operations

### Disk partition

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

### Add a HDD disk to Proxmox

```bash
lsblk
```

```
NAME              MAJ:MIN  RM    SIZE  RO  TYPE  MOUNTPOINT
sda                 8:0     0  465.8G   0  disk
└─sda1              8:1     0  465.8G   0  part
  └─hdd-root      253:5     0    300G   0  lvm   /mnt/root
nvme0n1           259:0     0  465.8G   0  disk
├─nvme0n1p1       259:1     0   1007K   0  part
├─nvme0n1p2       259:2     0    512M   0  part  /boot/efi
└─nvme0n1p3       259:3     0  465.3G   0  part
  ├─pve-swap      253:0     0      8G   0  lvm   [SWAP]
  ├─pve-root      253:1     0     96G   0  lvm   /
  ├─pve-data_tmeta 253:2    0    3.5G   0  lvm
  │ └─pve-data    253:4     0  338.4G   0  lvm
  └─pve-data_tdata 253:3    0  338.4G   0  lvm
    └─pve-data    253:4     0  338.4G   0  lvm
```

Create physical volume:

```bash
pvcreate /dev/sda1
```

Create Volume group **hdd**:

```bash
vgcreate hdd /dev/sda1
```

Create logical volume (450G) in **hdd** for Backups, ISO-Images etc.:

```bash
lvcreate -L 450G -n root hdd
mkfs.ext4 -L hdd-root /dev/hdd/root
```

Create a mount point:

```bash
mkdir -p /mnt/root
```

Edit `/etc/fstab` and add the mount entry:

```bash
nano /etc/fstab
```

```
/dev/hdd/root /mnt/root ext4 errors=remount-ro 0 1
```

Mount logical volume:

```bash
mount -a
```

#### Create a Directory Storage

**Datacenter → Storage → Add → Directory**

| Field     | Value      |
|-----------|------------|
| ID        | hdd-root   |
| Directory | /mnt/root  |

---

## Useful Commands

> Reference: [LVM basics & commands](https://dannyda.com/2020/05/10/how-to-delete-remove-local-lvm-from-proxmox-ve-pve-and-some-lvm-basics-commands/)

### VM Management

```bash
# List all VMs
qm list

# Start / stop / reboot / shutdown
qm start <vmid>
qm stop <vmid>
qm reboot <vmid>
qm shutdown <vmid>

# VM status and config
qm status <vmid>
qm config <vmid>

# Remove VM
qm destroy <vmid>

# Snapshots
qm snapshot <vmid> <snapname>
qm rollback <vmid> <snapname>
qm listsnapshot <vmid>

# Enter VM terminal
qm terminal <vmid>
```

### Unlock locked virtual machine

```bash
rm -f /var/lock/qemu-server/lock-101.conf
qm unlock 100
qm stop 100
```

### Kill VM process

```bash
ps aux | grep "/usr/bin/kvm -id <VID>"
kill -9 <PID>
```

### Container (LXC) Management

```bash
# List all containers
pct list

# Start / stop / reboot
pct start <ctid>
pct stop <ctid>
pct reboot <ctid>

# Enter container shell
pct enter <ctid>

# Config and snapshots
pct config <ctid>
pct snapshot <ctid> <snapname>
pct rollback <ctid> <snapname>
```

### Disk & LVM Info

> **pv** = Physical Volume · **vg** = Volume Group · **lv** = Logical Volume

```bash
# Block devices
lsblk

# Detailed info
pvdisplay /dev/nvme0n1p3
vgdisplay hdd
lvdisplay /dev/pve/root
lvdisplay /dev/hdd/root

# Short summary
pvs
vgs
lvs
```

### Storage

```bash
# List storages and status
pvesm status

# List storage contents
pvesm list <storage>

# Resize VM disk
qm resize <vmid> <disk> +10G
```

### Backup & Restore

```bash
# Backup VM
vzdump <vmid> --storage <storage> --mode snapshot --compress zstd

# Restore VM
qmrestore /var/lib/vz/dump/<backup.vma.zst> <vmid>

# Restore container
pct restore <ctid> /var/lib/vz/dump/<backup.tar.zst>
```

### Network

```bash
# Reload network interfaces
ifreload -a

# Show interfaces
ip a

# Monitor traffic
iftop -i vmbr0
```

### Logs & Monitoring

```bash
# PVE service logs
journalctl -u pveproxy -f
journalctl -u pvedaemon -f

# Node resource status
pvesh get /nodes/<nodename>/status

# Cluster status
pvecm status
pvecm nodes
```
