# Self-Healing OS — Phase 1: Autonomous Fault Detection and Recovery on Alpine Linux

A lightweight, shell-script-based self-healing system for Alpine Linux that automatically detects and recovers from three categories of OS-level failure — with no human intervention required after startup.

Built as Phase 1 of a research project at Siddaganga Institute of Technology (SIT), Tumkur, exploring autonomous operating system recovery using the Monitor–Analyze–Plan–Execute (MAPE) loop.

---

## What It Does

A background monitor script polls all three detection checks every 10 seconds. When a failure is detected, the corresponding patch script is triggered automatically and the result is logged. The entire detect → patch → verify cycle completes within a single 10-second monitor interval.

| Failure Type | How Simulated | Auto-Recovery |
|---|---|---|
| Disk full (`/tmp` tmpfs) | `dd` writes 482MB junk file to RAM | Delete junk, clean old files |
| Service crash (`sshd`) | `rc-service sshd stop` | `rc-service sshd start` |
| Device removed (`/dev/sdb`) | Kernel-level sysfs delete | SCSI rescan + remount |

**Proven result:** All three failures detected and healed in a single 10-second monitor cycle, with zero manual interaction after the crashes were triggered.

---

## Architecture

```
monitor.sh  (runs every 10 seconds)
│
├── detect_disk.sh    ──── FAIL? ──→  patch_disk.sh    → verify
├── detect_service.sh ──── FAIL? ──→  patch_service.sh → verify
└── detect_device.sh  ──── FAIL? ──→  patch_device.sh  → verify

All output logged to /var/log/monitor.log
```

This maps directly onto the MAPE autonomic computing loop:

- **Monitor** — `detect_*.sh` scripts poll system state
- **Analyze** — exit code check (`0` = healthy, `1` = failure)
- **Plan** — each failure type maps to a fixed patch script
- **Execute** — `patch_*.sh` scripts apply recovery automatically

---

## Key Research Findings

### 1. Partition-aware monitoring is essential
Alpine mounts `/tmp` as a `tmpfs` — a RAM-backed filesystem capped at ~483MB, entirely separate from the root disk (23GB). A monitor that only checks the root partition would miss a full `tmpfs` entirely.

### 2. Read-based health checks can produce false negatives
The first version of `detect_device.sh` used `ls /mnt/fakeusb` as its health check. This was unreliable: the Linux kernel caches directory listings in RAM (the page cache), so `ls` returned results from memory even after the physical device was removed.

**Fix:** Switch to a write-based health check. Writes cannot be served from the page cache — they must reach the physical device. A `timeout`-wrapped write that fails or times out reliably exposes a dead or disconnected device.

> This finding generalises: **read-based health checks are unreliable for block device failure detection. Write-based checks should be the standard approach in self-healing systems.**

### 3. OpenRC vs systemd — Alpine-specific service management
All service commands use `rc-service` (OpenRC), not `systemctl` (systemd). This distinction is critical for any automated or AI-generated patches targeting Alpine Linux: `systemctl` commands generated from Ubuntu training examples do not exist on Alpine.

### 4. Retry counter persistence
The device patch's attempt counter is stored in `/tmp` (tmpfs), which is wiped on reboot. In a production system, the counter should be stored in `/var/lib/` to correctly cap total recovery attempts across reboots.

---

## Repository Structure

```
self-healing-os/
├── scripts/
│   ├── detect_disk.sh      # Check /tmp usage > 85%
│   ├── patch_disk.sh       # Clean /tmp junk files
│   ├── detect_service.sh   # Check sshd status via OpenRC
│   ├── patch_service.sh    # Restart sshd via OpenRC
│   ├── detect_device.sh    # Write-test /mnt/fakeusb
│   ├── patch_device.sh     # SCSI rescan + remount /dev/sdb
│   └── monitor.sh          # Unified MAPE loop (all 3 checks)
├── simulate/
│   └── trigger_all.sh      # Trigger all 3 failures simultaneously
├── docs/
│   └── setup.md            # Full VM and environment setup guide
├── LICENSE                 # MIT
└── README.md
```

---

## Quick Start

See [docs/setup.md](docs/setup.md) for complete VM setup instructions.

```sh
# 1. Install scripts
cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh

# 2. Start the monitor
/usr/local/bin/monitor.sh > /var/log/monitor.log 2>&1 &

# 3. Watch live output
tail -f /var/log/monitor.log

# 4. Trigger all three failures and watch auto-recovery
sh simulate/trigger_all.sh
```

---

## Environment

| Component | Detail |
|---|---|
| OS | Alpine Linux (musl libc + BusyBox + OpenRC) |
| Virtualization | Oracle VirtualBox on Windows host |
| Access | SSH via NAT port forwarding (host 2222 → guest 22) |
| Secondary disk | 100MB VDI attached as `/dev/sdb`, mounted at `/mnt/fakeusb` |

---

## Roadmap

This repository contains Phase 1 (baseline, no AI).

**Phase 2 — Safety Framework:** A 5-layer evaluation system for AI-generated patches: static analysis → system snapshot → sandbox execution → controlled live execution with kill switch → health check with auto-rollback.

---

## Research Context

This project is part of undergraduate research at [Siddaganga Institute of Technology](https://www.sit.ac.in/), Tumkur, Karnataka, India. Establishing a verified baseline before introducing AI-driven recovery in subsequent phases.

**Author:** Nimit Mishra (1SI24CS116),Nitin Sharma (1SI24CS118) Dept. of Computer Science and Engineering, SIT Tumkur  
**Supervisor:** Faculty, Dept. of CSE, SIT Tumkur  
**Date:** June 2026

---

## License

MIT — see [LICENSE](LICENSE)
