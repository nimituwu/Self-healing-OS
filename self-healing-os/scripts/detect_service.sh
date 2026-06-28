#!/bin/sh
# =============================================================================
# detect_service.sh — Detect SSH daemon (sshd) crash or stop
# =============================================================================
# Part of: Self-Healing OS — Phase 1 Baseline
# Author:  Nimit Mishra (1SI24CS116) and Nitin Sharma (1SI24CS118), SIT Tumkur
# License: MIT 
#
# Description:
#   Checks whether the sshd service is running using OpenRC's rc-service.
#   Returns exit code 1 if the service is stopped or crashed, exit code 0
#   if it is running normally.
#
# Alpine Linux uses OpenRC (not systemd):
#   All service management uses rc-service, NOT systemctl.
#   This is a critical distinction for any automated or AI-generated patches
#   on Alpine — systemctl commands that work on Ubuntu/Fedora do not exist
#   on Alpine Linux.
#
#   rc-service <name> status  — query current state
#   rc-service <name> start   — start the service
#   rc-service <name> stop    — stop the service
#
# Exit codes:
#   0  — sshd is running (healthy)
#   1  — sshd is stopped or crashed (failure detected)
# =============================================================================

SERVICE="sshd"

# Query OpenRC for the current service status
STATUS=$(rc-service "$SERVICE" status 2>&1)

if echo "$STATUS" | grep -qi "stopped\|crashed"; then
    echo "DETECTED: $SERVICE is down (status: $STATUS)"
    exit 1
else
    echo "OK: $SERVICE is running"
    exit 0
fi
