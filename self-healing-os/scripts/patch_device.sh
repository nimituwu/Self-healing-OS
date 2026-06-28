#!/bin/sh
# =============================================================================
# patch_device.sh — Recover a removed or unmounted block device
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nimit Mishra (1SI24CS116), Nitin Sharma (1SI24CS118),SIT Tumkur
# License: MIT
#
# Description:
#   Attempts to rediscover and remount a block device (/dev/sdb) that has
#   been removed at the kernel level (simulating a physical hot-unplug).
#   Uses SCSI host rescan to trigger kernel rediscovery, then remounts.
#   Capped at MAX_ATTEMPTS retries to avoid an infinite recovery loop.
#
# Recovery strategy:
#   1. Increment and check the attempt counter.
#   2. Rescan all SCSI hosts via sysfs to rediscover the device.
#   3. Clear any stale mount with a lazy unmount.
#   4. Attempt to remount the device.
#   5. Reset the counter on success; leave it for the next poll on failure.
#
# Known limitation — retry counter persistence:
#   The attempt counter is stored in /tmp, which is a tmpfs and is wiped
#   on reboot. This means the retry limit resets across reboots. In a
#   production deployment, the counter should be stored in a persistent
#   location such as /var/lib/self-healing/ to survive restarts and
#   correctly cap total recovery attempts.
#
# Exit codes:
#   0  — remount successful (or max attempts reached, giving up)
#   1  — remount failed on this attempt (will retry on next monitor cycle)
# =============================================================================

MOUNT_POINT="/mnt/fakeusb"
DEVICE="/dev/sdb"
MAX_ATTEMPTS=3
ATTEMPT_FILE="/tmp/device_patch_attempts"

# Read current attempt count (0 if no file exists yet)
ATTEMPTS=$(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0)
ATTEMPTS=$((ATTEMPTS + 1))
echo "$ATTEMPTS" > "$ATTEMPT_FILE"

echo "[PATCH] Device recovery attempt $ATTEMPTS of $MAX_ATTEMPTS"

# Give up after MAX_ATTEMPTS to prevent endless recovery loops
if [ "$ATTEMPTS" -gt "$MAX_ATTEMPTS" ]; then
    echo "[PATCH] Max attempts reached — device likely requires physical reattachment"
    echo "[PATCH] Stopping automatic recovery. Restart monitor to reset counter."
    echo "PATCH_COMPLETE"
    exit 1
fi

# Rescan all SCSI hosts via sysfs to trigger kernel rediscovery of the device.
# This is the equivalent of the kernel noticing a USB device being plugged in.
echo "[PATCH] Rescanning SCSI hosts..."
for host in /sys/class/scsi_host/host*; do
    echo "- - -" > "$host/scan" 2>/dev/null
done
sleep 1   # Allow kernel time to process the rescan

# Clear any stale/broken mount entry with a lazy unmount
# (-l = lazy: detach immediately, cleanup when last reference is dropped)
umount -l "$MOUNT_POINT" 2>/dev/null

# Attempt to remount the device
mount "$DEVICE" "$MOUNT_POINT" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[PATCH] Remounted $DEVICE at $MOUNT_POINT successfully"
    rm -f "$ATTEMPT_FILE"   # Reset counter on success
    echo "PATCH_COMPLETE"
    exit 0
else
    echo "[PATCH] Remount failed on attempt $ATTEMPTS/$MAX_ATTEMPTS — will retry next cycle"
    echo "PATCH_COMPLETE"
    exit 1
fi
