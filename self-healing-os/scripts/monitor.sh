#!/bin/sh
# =============================================================================
# monitor.sh — Unified MAPE-loop monitor (all three failure types)
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nimit Mishra (1SI24CS116) and Nitin Sharma (1SI24CS118),SIT Tumkur
# License: MIT
#
# Description:
#   The core of the self-healing system. Runs in an infinite loop, polling
#   all three detection scripts every INTERVAL seconds. When any detect
#   script returns a non-zero exit code (failure found), the corresponding
#   patch script is triggered automatically and all activity is logged.
#
#   No human input is required after the monitor is started. The only
#   manual action during research was triggering the simulated failures.
#
# 
#
# Usage:
#   # Run in background, log all output:
#   /usr/local/bin/monitor.sh > /var/log/monitor.log 2>&1 &
#
#   # Watch live:
#   tail -f /var/log/monitor.log
#
#   # Stop:
#   pkill -f monitor.sh
#
# Log location: /var/log/monitor.log
# =============================================================================

INTERVAL=10   # Seconds between each full check cycle
SCRIPT_DIR="/usr/local/bin"
LOG_TAG="self-healing-monitor"

echo "======================================"
echo "  Self-Healing OS Monitor — Started"
echo "  Polling interval: ${INTERVAL}s"
echo "  Watching: disk | sshd | /dev/sdb"
echo "======================================"

while true; do
    DATE=$(date '+%Y-%m-%d %H:%M:%S')

    # ── Check 1: Disk / tmpfs full ────────────────────────────────────────
    "$SCRIPT_DIR/detect_disk.sh" > /tmp/disk_check.log 2>&1
    if [ $? -ne 0 ]; then
        echo "[$DATE] [DISK] Failure detected — initiating auto-heal..."
        "$SCRIPT_DIR/patch_disk.sh"
        echo "[$DATE] [DISK] Auto-heal complete."
    fi

    # ── Check 2: Service crash (sshd) ─────────────────────────────────────
    "$SCRIPT_DIR/detect_service.sh" > /tmp/service_check.log 2>&1
    if [ $? -ne 0 ]; then
        echo "[$DATE] [SERVICE] Failure detected — initiating auto-heal..."
        "$SCRIPT_DIR/patch_service.sh"
        echo "[$DATE] [SERVICE] Auto-heal complete."
    fi

    # ── Check 3: Device / driver error (/dev/sdb) ─────────────────────────
    "$SCRIPT_DIR/detect_device.sh" > /tmp/device_check.log 2>&1
    if [ $? -ne 0 ]; then
        echo "[$DATE] [DEVICE] Failure detected — initiating auto-heal..."
        "$SCRIPT_DIR/patch_device.sh"
        echo "[$DATE] [DEVICE] Auto-heal complete."
    fi

    sleep "$INTERVAL"
done
