# Setup Guide

## Prerequisites

- Oracle VirtualBox (any recent version) on Windows, macOS, or Linux
- Alpine Linux ISO: https://alpinelinux.org/downloads/ (Standard x86_64)
- Approximately 1GB disk space for the VM

---

## Step 1 — Create the Alpine Linux VM

1. Open VirtualBox → New
2. Name: `AlpineTest` | Type: Linux | Version: Other Linux (64-bit)
3. RAM: 512MB (minimum); 1024MB recommended
4. Create a virtual disk: 25GB, VDI, dynamically allocated
5. Boot from the Alpine ISO and follow the `setup-alpine` wizard
   - Keyboard: `us`
   - Hostname: `alpinetest`
   - Network: `eth0`, DHCP, no manual config
   - Root password: set something memorable
   - Disk: `sda`, `sys` mode (installs to disk)
6. Reboot after install; eject the ISO

---

## Step 2 — Configure SSH Access (NAT port forwarding)

Alpine's default VirtualBox network is NAT, which isolates the VM. To SSH in from your host:

1. In VirtualBox: VM Settings → Network → Adapter 1 → Advanced → Port Forwarding
2. Add rule: Name `ssh` | Protocol `TCP` | Host Port `2222` | Guest Port `22`
3. Inside Alpine, start sshd:
   ```sh
   apk add openssh
   rc-service sshd start
   rc-update add sshd default
   ```
4. From Windows host: `ssh root@127.0.0.1 -p 2222`

---

## Step 3 — Create and Attach the Fake USB Disk

On your **Windows host** (in PowerShell or Command Prompt):

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createmedium disk `
  --filename "C:\Users\YourName\VirtualBox VMs\fake_usb.vdi" `
  --size 100 --format VDI
```

Then attach it: VirtualBox → VM Settings → Storage → Add Hard Disk → Choose `fake_usb.vdi`

---

## Step 4 — Format and Mount the Fake USB (inside Alpine)

```sh
# Format as ext4
mkfs.ext4 /dev/sdb

# Create mount point
mkdir -p /mnt/fakeusb

# Mount
mount /dev/sdb /mnt/fakeusb

# Verify
df -h /mnt/fakeusb
```

---

## Step 5 — Install the Scripts

```sh
# Copy all scripts to /usr/local/bin
cp scripts/*.sh /usr/local/bin/

# Make them executable
chmod +x /usr/local/bin/detect_disk.sh
chmod +x /usr/local/bin/patch_disk.sh
chmod +x /usr/local/bin/detect_service.sh
chmod +x /usr/local/bin/patch_service.sh
chmod +x /usr/local/bin/detect_device.sh
chmod +x /usr/local/bin/patch_device.sh
chmod +x /usr/local/bin/monitor.sh

# Create log directory
mkdir -p /var/log
```

---

## Step 6 — Start the Monitor

```sh
# Start in background, logging all output
/usr/local/bin/monitor.sh > /var/log/monitor.log 2>&1 &

# Confirm it is running
ps aux | grep monitor.sh

# Watch live output
tail -f /var/log/monitor.log
```

---

## Step 7 — Run the Concurrent Failure Test

```sh
# Make the simulation script executable and run it
chmod +x simulate/trigger_all.sh
sh simulate/trigger_all.sh

# Wait ~20 seconds, then check the log
cat /var/log/monitor.log
```

---

## Stopping the Monitor

```sh
pkill -f monitor.sh
```
