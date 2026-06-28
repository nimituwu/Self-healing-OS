#!/bin/sh
# =============================================================================
# trigger_all.sh — Simulate all three failures simultaneously
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nimit Mishra (1SI24CS116),Nitin Sharma(1SI24CS118), SIT Tumkur
# License: MIT
#
# WARNING: This script intentionally breaks your system for testing.
#   Run ONLY inside the Alpine Linux VirtualBox VM.
#   Do NOT run on a real machine or any system you care about.
#
# What this does:
#   1. Fills /tmp (tmpfs) to 100% using dd
#   2. Stops the SSH daemon (sshd) via OpenRC
#   3. Unmounts /mnt/fakeusb and removes /dev/sdb at the kernel level
#
# After running this, wait ~20 seconds and check /var/log/monitor.log
# to see all three failures detected and healed automatically.
#
# Prerequisites:
#   - monitor.sh must already be running in the background
#   - /dev/sdb must be attached and mounted at /mnt/fakeusb
#   - See docs/setup.md for full setup instructions
# =============================================================================

echo "============================================="
echo "  Self-Healing OS — Concurrent Failure Test"
echo "  Triggering all 3 failures simultaneously..."
echo "============================================="
echo ""
echo "WARNING: This will fill /tmp, stop sshd, and remove /dev/sdb."
printf "Continue? (yes/no): "
read CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "[1/3] Filling /tmp to 100% (writing 500MB of zeros)..."
dd if=/dev/zero of=/tmp/bigfile bs=1M count=500 2>/dev/null
echo "      Done. $(df -h /tmp | awk 'NR==2{print $5}') used."

echo ""
echo "[2/3] Stopping sshd..."
rc-service sshd stop
echo "      Done."

echo ""
echo "[3/3] Simulating device removal (/dev/sdb)..."
umount /mnt/fakeusb 2>/dev/null
echo 1 > /sys/block/sdb/device/delete
echo "      Done."

echo ""
echo "============================================="
echo "  All 3 failures triggered."
echo "  Monitor will auto-heal within ~10 seconds."
echo "  Watch: tail -f /var/log/monitor.log"
echo "============================================="
