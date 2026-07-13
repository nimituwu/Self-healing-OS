#!/bin/sh
# =============================================================================
# safe_heal.sh — Phase 2 Orchestrator: chains all 5 safety layers
# =============================================================================
# Part of: Self-Healing OS — Phase 2 Safety Pipeline
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   Called by monitor.sh instead of patch scripts directly. Wraps every
#   patch in 5 protective layers before it touches the live system.
#
# Usage:
#   safe_heal.sh <FAILURE_TYPE> <patch_script>
#   e.g. safe_heal.sh DISK_FULL /usr/local/bin/patch_disk.sh
#
# Exit code protocol:
#   0  = healed successfully
#   1  = failed (aborted at some layer, system safe or rolled back)
# =============================================================================

FAILURE_TYPE="$1"
PATCH_FILE="$2"

echo ""
echo "############################################"
echo "# SAFE HEAL STARTING"
echo "# Failure : $FAILURE_TYPE"
echo "# Patch   : $PATCH_FILE"
echo "# Time    : $(date)"
echo "############################################"

echo ""
echo "--- LAYER 1: Static Analysis ---"
/usr/local/bin/validator.sh "$PATCH_FILE"
if [ $? -ne 0 ]; then
    echo "[SAFE_HEAL] ABORTED at Layer 1 — patch rejected by validator"
    exit 1
fi

echo ""
echo "--- LAYER 2: System Snapshot ---"
/usr/local/bin/snapshot.sh take
if [ $? -ne 0 ]; then
    echo "[SAFE_HEAL] ABORTED at Layer 2 — snapshot failed"
    exit 1
fi

echo ""
echo "--- LAYER 3: Sandbox Execution ---"
/usr/local/bin/sandbox.sh "$PATCH_FILE"
if [ $? -ne 0 ]; then
    echo "[SAFE_HEAL] ABORTED at Layer 3 — patch failed in sandbox"
    echo "[SAFE_HEAL] Real system was never touched"
    exit 1
fi

echo ""
echo "--- LAYER 4: Live Execution with Watchdog ---"
/usr/local/bin/executor.sh "$PATCH_FILE"
EXEC_CODE=$?

if [ "$EXEC_CODE" -eq 2 ]; then
    echo "[SAFE_HEAL] Patch killed by watchdog — rolling back"
    /usr/local/bin/snapshot.sh restore
    exit 1
fi

if [ "$EXEC_CODE" -ne 0 ]; then
    echo "[SAFE_HEAL] Patch failed during execution — rolling back"
    /usr/local/bin/snapshot.sh restore
    exit 1
fi

echo ""
echo "--- LAYER 5: Health Check ---"
/usr/local/bin/healthcheck.sh "$FAILURE_TYPE"
if [ $? -ne 0 ]; then
    echo "[SAFE_HEAL] Health check failed — system rolled back"
    exit 1
fi

echo ""
echo "############################################"
echo "# SAFE HEAL COMPLETE — System Healed"
echo "# Failure : $FAILURE_TYPE"
echo "# Time    : $(date)"
echo "############################################"
exit 0
