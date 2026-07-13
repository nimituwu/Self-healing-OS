#!/bin/sh
# sandbox.sh — Layer 3: Chroot jail execution
# Part of: Self-Healing OS — Phase 2 Safety Pipeline
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur — MIT License
# KEY FINDING: sandbox must live in /var/tmp, not /tmp (circular dependency)

PATCH_FILE="$1"
SANDBOX_DIR="/var/tmp/sandbox_$$"

echo "============================================"
echo "[SANDBOX] Preparing isolated environment..."
echo "[SANDBOX] Sandbox dir: $SANDBOX_DIR"
echo "============================================"

mkdir -p "$SANDBOX_DIR/bin" "$SANDBOX_DIR/tmp" "$SANDBOX_DIR/etc" \
         "$SANDBOX_DIR/var/log" "$SANDBOX_DIR/lib"

cp /bin/busybox "$SANDBOX_DIR/bin/busybox"
cp /lib/ld-musl-x86_64.so.1 "$SANDBOX_DIR/lib/ld-musl-x86_64.so.1"

cd "$SANDBOX_DIR/bin"
for CMD in sh echo rm find df mkdir sleep cat grep; do
    ln -sf busybox $CMD
done
cd /

cp /etc/passwd "$SANDBOX_DIR/etc/passwd"
cp /etc/hosts  "$SANDBOX_DIR/etc/hosts"
cp "$PATCH_FILE" "$SANDBOX_DIR/tmp/patch.sh"
chmod +x "$SANDBOX_DIR/tmp/patch.sh"

echo "[SANDBOX] Fake filesystem ready"
echo "[SANDBOX] Running patch in isolation..."

chroot "$SANDBOX_DIR" /bin/sh /tmp/patch.sh > /var/tmp/sandbox_output.log 2>&1
EXIT_CODE=$?

echo "[SANDBOX] Patch finished — exit code: $EXIT_CODE"
echo "[SANDBOX] --- Output start ---"
cat /var/tmp/sandbox_output.log
echo "[SANDBOX] --- Output end ---"

if grep -q "PATCH_COMPLETE" /var/tmp/sandbox_output.log; then
    echo "[SANDBOX] PASSED: Patch completed in sandbox"
    RESULT=0
else
    echo "[SANDBOX] FAILED: Patch did not complete in sandbox"
    RESULT=1
fi

rm -rf "$SANDBOX_DIR"
rm -f /var/tmp/sandbox_output.log
echo "[SANDBOX] Sandbox cleaned up"
echo "============================================"
exit $RESULT
