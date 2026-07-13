#!/bin/sh
# =============================================================================
# healthcheck.sh — Layer 5: Post-patch health verification and auto-rollback
# =============================================================================
# Part of: Self-Healing OS — Phase 2 Safety Pipeline
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   After the patch runs on the live system, compares current state against
#   the expected post-patch outcome for the given failure type. If the system
#   did not improve, triggers automatic rollback using the Layer 2 snapshot.
#
# Exit codes:
#   0  — system healthy, no rollback needed
#   1  — system did not improve, snapshot restored automatically
# =============================================================================

FAILURE_TYPE="$1"

echo "============================================"
echo "[HEALTH] Running post-patch health check"
echo "[HEALTH] Failure type: $FAILURE_TYPE"
echo "============================================"

DISK_NOW=$(df /tmp | awk 'NR==2{print $5}' | tr -d '%')
MEM_NOW=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
SSHD_NOW=$(rc-service sshd status 2>&1)
DEVICE_NOW=$(mountpoint -q /mnt/fakeusb && echo "mounted" || echo "unmounted")

echo "[HEALTH] Current state:"
echo "         Disk /tmp : ${DISK_NOW}%"
echo "         Memory    : ${MEM_NOW}%"
echo "         sshd      : $SSHD_NOW"
echo "         Device    : $DEVICE_NOW"

WORSE=0
REASON=""

case "$FAILURE_TYPE" in
    DISK_FULL)
        if [ "$DISK_NOW" -gt 85 ]; then
            WORSE=1
            REASON="Disk still at ${DISK_NOW}% after patch"
        fi
        ;;
    SERVICE_CRASH)
        if echo "$SSHD_NOW" | grep -qi "stopped\|crashed"; then
            WORSE=1
            REASON="sshd still down after patch"
        fi
        ;;
    DEVICE_ERROR)
        if [ "$DEVICE_NOW" = "unmounted" ]; then
            WORSE=1
            REASON="Device still unmounted after patch"
        fi
        ;;
    *)
        if [ "$DISK_NOW" -gt 95 ]; then
            WORSE=1
            REASON="Disk critically high at ${DISK_NOW}%"
        fi
        ;;
esac

if [ "$WORSE" -eq 1 ]; then
    echo "[HEALTH] FAILED: System did not improve — $REASON"
    echo "[HEALTH] Triggering automatic rollback..."
    /usr/local/bin/snapshot.sh restore
    echo "[HEALTH] Rollback complete"
    exit 1
else
    echo "[HEALTH] PASSED: System is healthy after patch"
    echo "[HEALTH] No rollback needed"
    exit 0
fi
