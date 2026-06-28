#!/bin/sh
# =============================================================================
# patch_disk.sh — Recover from /tmp (tmpfs) disk exhaustion
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nitin Sharma (1SI24CS118),Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   Cleans /tmp by removing the simulated junk file and any files older than
#   1 day. Called automatically by monitor.sh when detect_disk.sh returns
#   exit code 1.
#
# Recovery strategy:
#   1. Remove the known simulation file (/tmp/bigfile) if present.
#   2. Remove any regular files in /tmp older than 1 day (safe cleanup).
#   3. Log the post-patch disk state for verification.
#
# Note:
#   In production, step 1 would be replaced by a more general cleanup
#   strategy (e.g., targeting large files above a size threshold rather
#   than a named file). The named-file removal is specific to the simulation.
# =============================================================================

echo "[PATCH] Cleaning /tmp..."

# Remove the simulated junk file (created by simulate/fill_disk.sh)
rm -f /tmp/bigfile

# Remove any temp files older than 1 day as general hygiene
find /tmp -type f -mtime +1 -delete 2>/dev/null

# Show post-patch disk state for verification in logs
df -h /tmp

echo "PATCH_COMPLETE"
