#!/bin/sh
# =============================================================================
# executor.sh — Layer 4: Controlled live execution with watchdog
# =============================================================================
# Part of: Self-Healing OS — Phase 2 Safety Pipeline (updated in Phase 3)
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   Runs the patch on the live system as a background process while a
#   watchdog loop monitors for three kill conditions every 2 seconds.
#   If any condition triggers, the patch is killed immediately (kill -9)
#   and exit code 2 signals the orchestrator to invoke rollback.
#
# Kill conditions:
#   TIMEOUT   — patch runs for more than 60 seconds
#   DISK GROW — disk usage increases AND exceeds 95% during patch
#   CPU SPIKE — CPU usage exceeds 90%
#
# Phase 3 update — executor log moved from /tmp to /var/tmp:
#   The original executor wrote its output log to /tmp/executor_output.log.
#   When the failure being healed is DISK_FULL (/tmp at 100%), creating
#   this log file fails silently — another instance of the circular
#   dependency problem discovered in Phase 2 (sandbox in /tmp).
#   Fix: log moved to /var/tmp/executor_output.log, which lives on the
#   main ext4 disk (/dev/sda3, 22.8GB) — unaffected by tmpfs exhaustion.
#
# Timing imprecision:
#   Watchdog polls every 2 seconds — timeout enforcement has up to 2s
#   imprecision. A 60s timeout may allow up to 62s before kill.
#   Observed: sleep 120 patch killed at 66s (within expected range).
#
# Exit codes:
#   0  — patch completed successfully (PATCH_COMPLETE in output)
#   1  — patch failed gracefully (no rollback needed)
#   2  — patch killed by watchdog (rollback required)
# =============================================================================

PATCH_FILE="$1"
TIMEOUT=60
MAX_CPU=90
EXEC_LOG="/var/tmp/executor_output.log"   # Phase 3: moved from /tmp

echo "============================================"
echo "[EXECUTOR] Starting controlled execution"
echo "[EXECUTOR] Patch: $PATCH_FILE"
echo "[EXECUTOR] Timeout: ${TIMEOUT}s  Max CPU: ${MAX_CPU}%"
echo "============================================"

DISK_BEFORE=$(df /tmp | awk 'NR==2{print $5}' | tr -d '%')
echo "[EXECUTOR] Disk before: ${DISK_BEFORE}%"

sh "$PATCH_FILE" > "$EXEC_LOG" 2>&1 &
PATCH_PID=$!
echo "[EXECUTOR] Patch running as PID: $PATCH_PID"

START_TIME=$(date +%s)
KILLED=0
KILL_REASON=""

while kill -0 $PATCH_PID 2>/dev/null; do
    sleep 2
    ELAPSED=$(( $(date +%s) - START_TIME ))

    # Kill condition 1: Timeout
    if [ "$ELAPSED" -gt "$TIMEOUT" ]; then
        KILL_REASON="TIMEOUT after ${ELAPSED}s"
        kill -9 $PATCH_PID 2>/dev/null
        KILLED=1
        break
    fi

    # Kill condition 2: Disk growing
    DISK_NOW=$(df /tmp | awk 'NR==2{print $5}' | tr -d '%')
    if [ "$DISK_NOW" -gt "$DISK_BEFORE" ] && [ "$DISK_NOW" -gt 95 ]; then
        KILL_REASON="DISK GROWING: ${DISK_BEFORE}% -> ${DISK_NOW}%"
        kill -9 $PATCH_PID 2>/dev/null
        KILLED=1
        break
    fi

    # Kill condition 3: CPU spike
    CPU=$(top -bn1 2>/dev/null | grep "CPU" | awk '{print $2}' | tr -d '%' | cut -d. -f1)
    if [ -n "$CPU" ] && [ "$CPU" -gt "$MAX_CPU" ] 2>/dev/null; then
        KILL_REASON="CPU SPIKE: ${CPU}%"
        kill -9 $PATCH_PID 2>/dev/null
        KILLED=1
        break
    fi

    echo "[EXECUTOR] Running... ${ELAPSED}s elapsed, disk: ${DISK_NOW}%"
done

echo "[EXECUTOR] --- Patch output ---"
cat "$EXEC_LOG" 2>/dev/null || echo "[EXECUTOR] (no output captured)"
echo "[EXECUTOR] --- End output ---"

if [ "$KILLED" -eq 1 ]; then
    echo "[EXECUTOR] KILLED by watchdog: $KILL_REASON"
    echo "[EXECUTOR] FAILED — triggering rollback"
    rm -f "$EXEC_LOG"
    exit 2
fi

if grep -q "PATCH_COMPLETE" "$EXEC_LOG" 2>/dev/null; then
    echo "[EXECUTOR] PASSED: Patch completed successfully"
    rm -f "$EXEC_LOG"
    exit 0
else
    echo "[EXECUTOR] FAILED: Patch did not complete"
    rm -f "$EXEC_LOG"
    exit 1
fi
