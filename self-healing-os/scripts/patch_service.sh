#!/bin/sh
# =============================================================================
# patch_service.sh — Restart a crashed or stopped SSH daemon (sshd)
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nitin Sharma(1SI24CS118),Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   Restarts the sshd service using OpenRC's rc-service command.
#   Called automatically by monitor.sh when detect_service.sh returns
#   exit code 1.
#
# Note on Alpine Linux / OpenRC:
#   Uses rc-service (OpenRC init system), NOT systemctl (systemd).
#   Do not substitute "systemctl start sshd" — that command does not
#   exist on Alpine Linux.
# =============================================================================

echo "[PATCH] Restarting sshd..."

# Restart the SSH daemon via OpenRC
rc-service sshd start

# Show all service states as confirmation in the log
rc-status

echo "PATCH_COMPLETE"
