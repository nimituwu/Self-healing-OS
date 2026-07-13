#!/bin/sh
# snapshot.sh — Layer 2: System snapshot and rollback
# Part of: Self-Healing OS — Phase 2 Safety Pipeline
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur — MIT License

ACTION="$1"
SNAP_DIR="/var/lib/healer/snapshots"
SNAP_PATH="$SNAP_DIR/latest"

take_snapshot() {
    echo "[SNAPSHOT] Taking system snapshot..."
    mkdir -p "$SNAP_PATH"
    df -h > "$SNAP_PATH/disk.txt"
    rc-status --all > "$SNAP_PATH/services.txt" 2>/dev/null
    mount > "$SNAP_PATH/mounts.txt"
    cp /etc/passwd      "$SNAP_PATH/passwd.bak"   2>/dev/null
    cp /etc/fstab       "$SNAP_PATH/fstab.bak"    2>/dev/null
    cp /etc/hosts       "$SNAP_PATH/hosts.bak"    2>/dev/null
    cp /etc/resolv.conf "$SNAP_PATH/resolv.bak"   2>/dev/null
    date > "$SNAP_PATH/timestamp.txt"
    echo "[SNAPSHOT] Snapshot saved to $SNAP_PATH"
    echo "[SNAPSHOT] Timestamp: $(cat $SNAP_PATH/timestamp.txt)"
}

restore_snapshot() {
    echo "[SNAPSHOT] Restoring from snapshot..."
    if [ ! -d "$SNAP_PATH" ]; then
        echo "[SNAPSHOT] FAIL: No snapshot found at $SNAP_PATH"
        exit 1
    fi
    echo "[SNAPSHOT] Snapshot was taken at: $(cat $SNAP_PATH/timestamp.txt)"
    cp "$SNAP_PATH/passwd.bak"  /etc/passwd      2>/dev/null && echo "[SNAPSHOT] Restored /etc/passwd"
    cp "$SNAP_PATH/fstab.bak"   /etc/fstab       2>/dev/null && echo "[SNAPSHOT] Restored /etc/fstab"
    cp "$SNAP_PATH/hosts.bak"   /etc/hosts       2>/dev/null && echo "[SNAPSHOT] Restored /etc/hosts"
    cp "$SNAP_PATH/resolv.bak"  /etc/resolv.conf 2>/dev/null && echo "[SNAPSHOT] Restored /etc/resolv.conf"
    echo "[SNAPSHOT] Config files restored"
}

case "$ACTION" in
    take)    take_snapshot ;;
    restore) restore_snapshot ;;
    *) echo "[SNAPSHOT] Usage: snapshot.sh take | restore"; exit 1 ;;
esac
