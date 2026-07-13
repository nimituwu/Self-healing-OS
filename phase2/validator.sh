#!/bin/sh
# =============================================================================
# validator.sh — Layer 1: Static analysis of patch scripts
# =============================================================================
# Part of: Self-Healing OS — Phase 2 Safety Pipeline (updated in Phase 3)
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   Reads the patch file as plain text and applies four checks — without
#   ever executing the script. Rejects dangerous patterns, missing shebang,
#   syntax errors, and empty files.
#
# Phase 3 update — regex blacklist replacing fixed-string matching:
#   The original Phase 2 validator used grep -F (fixed string) for blacklist
#   checks. During Phase 3 testing, this caused a false positive:
#   "rm -rf /var/cache/apk/*" was rejected because grep -F found the
#   substring "rm -rf /" inside it — matching a safe command as dangerous.
#
#   Fix: switched to grep -E (regex) with anchored patterns.
#   "rm\s+-rf\s+/\s*$" matches only when "/" is at end of line (root deletion).
#   "rm -rf /var/cache/apk/*" does NOT match because "v" follows the slash.
#   This is the correct behaviour — dangerous patterns must be matched
#   structurally, not as substrings.
#
#   Additional Phase 3 patterns added:
#   - rc-service sshd stop (AI attempted this in Attempt 1)
#   - reboot, halt, shutdown (AI may generate these for service failures)
#   - rm -rf /var/tmp (protects sandbox and executor infrastructure)
#
# Exit codes:
#   0  — patch approved (all 4 checks passed)
#   1  — patch rejected (at least one check failed)
# =============================================================================

PATCH_FILE="$1"
ISSUES=0

echo "============================================"
echo "[VALIDATOR] Checking: $PATCH_FILE"
echo "============================================"

# Check 1: File must exist and not be empty
if [ ! -f "$PATCH_FILE" ]; then
    echo "[VALIDATOR] FAIL: File does not exist"
    exit 1
fi
if [ ! -s "$PATCH_FILE" ]; then
    echo "[VALIDATOR] FAIL: File is empty"
    exit 1
fi
echo "[VALIDATOR] Check 1 PASSED: File exists and has content"

# Check 2: Must start with #!/bin/sh
FIRST_LINE=$(head -1 "$PATCH_FILE")
if [ "$FIRST_LINE" != "#!/bin/sh" ]; then
    echo "[VALIDATOR] FAIL: Must start with #!/bin/sh"
    echo "[VALIDATOR] Found: $FIRST_LINE"
    exit 1
fi
echo "[VALIDATOR] Check 2 PASSED: Valid shebang"

# Check 3: Dangerous command blacklist
# Each pattern uses grep -E (regex) for structural matching.
# This prevents false positives from substring matches.
check_exact() {
    PATTERN="$1"
    LABEL="$2"
    if grep -qE "$PATTERN" "$PATCH_FILE" 2>/dev/null; then
        echo "[VALIDATOR] FAIL: Dangerous pattern: $LABEL"
        ISSUES=$((ISSUES + 1))
    fi
}

check_exact 'rm\s+-rf\s+/\s*$'            "rm -rf / (root deletion)"
check_exact 'rm\s+-rf\s+/\*'              "rm -rf /* (root wildcard)"
check_exact 'rm\s+-rf\s+/bin'             "rm -rf /bin"
check_exact 'rm\s+-rf\s+/etc'             "rm -rf /etc"
check_exact 'rm\s+-rf\s+/lib'             "rm -rf /lib"
check_exact 'rm\s+-rf\s+/usr'             "rm -rf /usr"
check_exact 'rm\s+-rf\s+/var/tmp'         "rm -rf /var/tmp (sandbox)"
check_exact 'rm\s+-rf\s+/tmp[^/]'         "rm -rf /tmp directly"
check_exact 'rm\s+-f\s+/tmp/\*'           "rm -f /tmp/* wildcard"
check_exact 'mkfs'                         "mkfs (formats disk)"
check_exact 'dd if=/dev/zero of=/dev/sd'  "dd disk wipe"
check_exact ':\(\)\{:\|:&\}'              "fork bomb"
check_exact 'chmod\s+-R\s+777\s+/'        "chmod 777 root"
check_exact '>\s*/etc/passwd'              "overwrite passwd"
check_exact 'rc-service sshd stop'         "stopping sshd (Phase 3 addition)"
check_exact '\bshutdown\b'                 "shutdown"
check_exact '\bhalt\b'                     "halt"
check_exact '\breboot\b'                   "reboot"

if [ "$ISSUES" -gt 0 ]; then
    echo "[VALIDATOR] REJECTED: $ISSUES dangerous pattern(s) found"
    exit 1
fi
echo "[VALIDATOR] Check 3 PASSED: No dangerous commands"

# Check 4: Shell syntax check (parse only, no execution)
sh -n "$PATCH_FILE" 2>/tmp/syntax_check.log
if [ $? -ne 0 ]; then
    echo "[VALIDATOR] FAIL: Syntax error in script"
    cat /tmp/syntax_check.log
    exit 1
fi
echo "[VALIDATOR] Check 4 PASSED: Syntax is valid"

echo "============================================"
echo "[VALIDATOR] APPROVED: Patch is safe to proceed"
echo "============================================"
exit 0
