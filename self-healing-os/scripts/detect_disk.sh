#!/bin/sh
# =============================================================================
# detect_disk.sh — Detect /tmp (tmpfs) disk exhaustion 
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nimit Mishra (1SI24CS116) and  Nitin Sharma (1SI24CS118),Tumkur
# License: MIT
#
# Description:
#   Checks the usage percentage of /tmp (a RAM-backed tmpfs on Alpine Linux).
#   Returns exit code 1 (failure) if usage exceeds the THRESHOLD, or exit
#   code 0 (healthy) otherwise.
#
# Why /tmp specifically?
#   Alpine mounts /tmp as tmpfs — a filesystem stored in RAM, capped at
#   ~483MB, entirely separate from the root disk (/dev/sda3, 23GB).
#   A naive check on the root partition would miss a full tmpfs entirely.
#   Partition-specific monitoring is therefore essential.
#
# Exit codes:
#   0  — /tmp usage is within acceptable limits (healthy)
#   1  — /tmp usage exceeds threshold (failure detected)
# =============================================================================

THRESHOLD=85   # Alert if /tmp usage exceeds this percentage

# Read current /tmp usage as a plain integer (e.g. 100, not "100%")
USAGE=$(df /tmp | awk 'NR==2{print $5}' | tr -d '%')

if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "DETECTED: /tmp at ${USAGE}% (threshold: ${THRESHOLD}%)"
    exit 1
else
    echo "OK: /tmp at ${USAGE}% (threshold: ${THRESHOLD}%)"
    exit 0
fi
