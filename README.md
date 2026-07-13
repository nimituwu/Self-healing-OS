# Self-Healing OS — Autonomous Fault Detection, Safe Patch Execution, and AI-Generated Recovery on Alpine Linux

A three-phase autonomous self-healing system for Alpine Linux that detects OS-level failures, validates patches through a 5-layer safety pipeline, and in Phase 3 generates repair patches using a locally-running AI model — with no human intervention required after startup.

Built as undergraduate research at Siddaganga Institute of Technology (SIT), Tumkur, exploring autonomous operating system recovery using the Monitor–Analyze–Plan–Execute (MAPE) loop and local AI patch generation.

---

## What Each Phase Proves

| Phase | Question | Answer |
|---|---|---|
| Phase 1 | Can we detect and fix OS failures automatically? | Yes — 3 failure types, healed within 10 seconds |
| Phase 2 | Can we guarantee a bad patch never makes things worse? | Yes — 5-layer safety pipeline, 4s overhead, auto-rollback |
| Phase 3 | Can a local AI generate correct OS-level repair patches? | Yes — with constrained prompts and the Phase 2 safety pipeline |

---

## Repository Structure

```
self-healing-os/
├── README.md
├── LICENSE
├── scripts/                     ← Phase 1: detect + patch scripts
│   ├── monitor.sh               ← MAPE loop daemon (polls every 10s)
│   ├── detect_disk.sh           ← Check /tmp usage > 85%
│   ├── patch_disk.sh            ← Clean /tmp junk files
│   ├── detect_service.sh        ← Check sshd via OpenRC
│   ├── patch_service.sh         ← Restart sshd via rc-service
│   ├── detect_device.sh         ← Write-test /mnt/fakeusb
│   └── patch_device.sh          ← SCSI rescan + remount /dev/sdb
├── simulate/
│   └── trigger_all.sh           ← Trigger all 3 failures at once
├── docs/
│   └── setup.md                 ← Full VM and environment setup guide
├── phase2/                      ← 5-layer safety pipeline
│   ├── safe_heal.sh             ← Orchestrator: chains all 5 layers
│   ├── validator.sh             ← Layer 1: static analysis (updated Phase 3)
│   ├── snapshot.sh              ← Layer 2: system snapshot + restore
│   ├── sandbox.sh               ← Layer 3: chroot jail test run
│   ├── executor.sh              ← Layer 4: live run + watchdog (updated Phase 3)
│   └── healthcheck.sh           ← Layer 5: verify + auto-rollback
└── phase3/
    └── ai_engine.sh             ← AI patch generation via local Ollama LLM
```

---

## Phase 1 — Baseline Monitor

A background MAPE loop polls three detection scripts every 10 seconds. On failure, the corresponding patch runs automatically.

| Failure | Simulated with | Auto-fix | Proven result |
|---|---|---|---|
| `/tmp` full (tmpfs) | `dd if=/dev/zero ... count=500` | Delete junk, clean old files | ✅ Healed |
| `sshd` crash (OpenRC) | `rc-service sshd stop` | `rc-service sshd start` | ✅ Healed |
| Device removed (`/dev/sdb`) | `echo 1 > /sys/block/sdb/device/delete` | SCSI rescan + remount | ✅ Healed |

**Result:** All three failures triggered simultaneously → all three healed in one 10-second cycle (2026-06-20 23:10:32). Zero false positives.

### Quick Start — Phase 1

```sh
cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh
/usr/local/bin/monitor.sh > /var/log/monitor.log 2>&1 &
tail -f /var/log/monitor.log
sh simulate/trigger_all.sh
```

---

## Phase 2 — 5-Layer Safety Pipeline

Every patch passes through 5 layers before touching the live system:

```
safe_heal.sh FAILURE_TYPE patch_script.sh
  │
  ├── Layer 1: validator.sh    → static analysis, never executes patch
  ├── Layer 2: snapshot.sh     → save system state for guaranteed rollback
  ├── Layer 3: sandbox.sh      → chroot jail test run
  ├── Layer 4: executor.sh     → live run + watchdog (timeout/disk/CPU)
  └── Layer 5: healthcheck.sh  → verify improvement, auto-rollback if worse
```

**Exit code protocol:**

| Code | Meaning | Rollback? |
|---|---|---|
| 0 | Layer passed | No |
| 1 | Rejected / failed gracefully | No (system untouched) |
| 2 | Killed mid-execution | Yes (snapshot restore) |

**End-to-end timing:** 4 seconds (2026-07-06 13:25:58 → 13:26:02 IST).

### Quick Start — Phase 2

```sh
cp phase2/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh

dd if=/dev/zero of=/tmp/bigfile bs=1M count=500
/usr/local/bin/safe_heal.sh DISK_FULL /usr/local/bin/patch_disk.sh
```

---

## Phase 3 — AI-Generated Patches via Local LLM

`ai_engine.sh` collects live system context, builds a constrained prompt, and queries a locally-running Ollama LLM (llama3.2) to generate a patch. The AI-generated patch is then handed to `safe_heal.sh` and evaluated through all 5 safety layers.

**Why local LLM?**  
No internet connection required. Suitable for offline deployments (remote servers, embedded systems). Ollama runs on the Windows host; the Alpine VM reaches it at `10.0.2.2:11434` (VirtualBox NAT gateway).

### Quick Start — Phase 3

```sh
# On Windows host: install Ollama and pull model
ollama pull llama3.2
ollama serve

# On Alpine VM: run AI-driven heal
cp phase3/ai_engine.sh /usr/local/bin/
chmod +x /usr/local/bin/ai_engine.sh

dd if=/dev/zero of=/tmp/bigfile bs=1M count=500

/usr/local/bin/ai_engine.sh DISK_FULL
/usr/local/bin/safe_heal.sh DISK_FULL /tmp/ai_generated_patch.sh
```

### Phase 3 Test Results — Three Attempts

| Attempt | Prompt | AI output | Validator result | Outcome |
|---|---|---|---|---|
| 1 | Open-ended | Stopped sshd, wiped /var/tmp, hallucinated `apk add disk-cleaner` | REJECTED Layer 1 | Dangerous patch blocked |
| 2 | Constrained | Correct minimal patch — but validator false positive | REJECTED Layer 1 | Safe patch incorrectly blocked |
| 3 | Constrained + regex validator | Correct minimal patch | APPROVED all layers | ✅ System healed in 3s |

---

## Key Research Findings

### 1. Partition-aware monitoring is essential
Alpine's `/tmp` is a RAM-backed tmpfs (483MB), completely separate from the root disk (22.8GB). A monitor watching only the root partition misses this entire failure class.

### 2. Read-based health checks produce false negatives
`ls /mnt/fakeusb` returned success from the page cache even after the device was removed at the kernel level. Write-based checks are required for reliable block device detection.

### 3. OpenRC vs systemd
Alpine has no `systemctl`. All service commands use `rc-service`. AI models trained on Ubuntu data generate wrong commands for Alpine — this is a concrete prompt engineering requirement.

### 4. Sandbox partition dependency (circular)
The sandbox originally built in `/tmp`. When `/tmp` is full, the sandbox cannot build itself — the safety infrastructure fails due to the exact condition it protects against. Fix: move sandbox to `/var/tmp` (separate partition).

### 5. Prompt engineering is safety-critical, not cosmetic
The same LLM model generated a dangerous patch (Attempt 1) and a correct safe patch (Attempt 3). Only the prompt changed. Explicit prohibitions and allowances are required.

### 6. LLM hallucination is a concrete risk
`apk add disk-cleaner` — the model invented a non-existent package name with full confidence. This validates the necessity of the 5-layer safety pipeline; without it, this patch would have run on the live system.

### 7. Blacklist design requires precision (regex not substring)
`grep -F "rm -rf /"` matched `rm -rf /var/cache/apk/*` as a substring, causing a false positive. `grep -E 'rm\s+-rf\s+/\s*$'` correctly distinguishes between root deletion (dangerous) and subdirectory deletion (safe).

### 8. Executor log circular dependency (Phase 3)
The executor originally logged to `/tmp/executor_output.log`. When `/tmp` is full, this fails silently. Fix: moved to `/var/tmp/executor_output.log`.

---

## Environment

| Component | Detail |
|---|---|
| OS | Alpine Linux (musl libc + BusyBox + OpenRC) |
| Virtualisation | Oracle VirtualBox on Windows 11 host |
| Access | SSH via NAT port forwarding (host 2222 → guest 22) |
| Secondary disk | 100MB VDI attached as `/dev/sdb`, mounted at `/mnt/fakeusb` |
| AI model | llama3.2 (3.2B params, Q4_K_M, ~2GB RAM) via Ollama |
| Ollama host | Windows PC (16GB RAM), reachable from VM at `10.0.2.2:11434` |

---

## Research Context

**Authors:** Nimit Mishra (1SI24CS116), Nitin Sharma — Dept. of CSE, SIT Tumkur  
**Supervisor:** Faculty, Dept. of CSE, SIT Tumkur  
**Period:** June–July 2026

---

## License

MIT — see [LICENSE](LICENSE)
