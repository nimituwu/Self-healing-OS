#!/bin/sh
# =============================================================================
# detect_device.sh — Detect removal or failure of a mounted block device
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nimit Mishra (1SI24CS116) and Nitin Sharma (1SI24CS118) ,Tumkur
# License: MIT
#
# Description:
#   Checks whether the device mounted at MOUNT_POINT is present AND writable.
#   Returns exit code 1 if the mount is absent or unresponsive, exit code 0
#   if the device is healthy.
#
# Key engineering finding — the page cache false negative:
#   An earlier version of this script used 'ls /mnt/fakeusb' as its health
#   check. This produced false negatives: the Linux kernel caches directory
#   listings in RAM (the page cache), so 'ls' returned results from memory
#   even after the physical device was removed.
#
#   The fix: use a WRITE test instead of a read test.
#   Writes cannot be served from the page cache — they must reach the
#   physical device. A timed write that times out or errors therefore
#   reliably indicates a dead or disconnected device.
#
#   This finding generalises: read-based health checks are unreliable for
#   block device detection. Write-based checks should be the standard
#   approach in self-healing systems.
#
# Exit codes:
#   0  — device is mounted and writable (healthy)
#   1  — device is unmounted or write-unresponsive (failure detected)
# =============================================================================

MOUNT_POINT="/mnt/fakeusb"
TEST_FILE="$MOUNT_POINT/.healthcheck"

# Check 1: Is the filesystem mounted at all?
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "DETECTED: $MOUNT_POINT is not mounted"
    exit 1
fi

# Check 2: Can we actually WRITE to the device?
# A 3-second timeout prevents the check from hanging if the device is
# unresponsive (e.g., kernel I/O waiting on a removed device).
timeout 3 sh -c "echo healthcheck > '$TEST_FILE'" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "DETECTED: $MOUNT_POINT is unresponsive (write timed out or failed)"
    exit 1
fi

# Clean up test artifact
rm -f "$TEST_FILE" 2>/dev/null

echo "OK: $MOUNT_POINT is healthy (mount present, write successful)"
exit 0
