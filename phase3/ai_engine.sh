#!/bin/sh
# =============================================================================
# ai_engine.sh — Phase 3: AI-generated patch creation via local LLM
# =============================================================================
# Part of: Self-Healing OS — Phase 3 AI Integration
# Author:  Nimit Mishra (1SI24CS116), SIT Tumkur
# License: MIT
#
# Description:
#   Collects current system context (disk usage, memory, OS info), builds a
#   prompt, and queries a locally-running Ollama LLM (llama3.2) to generate
#   a shell script patch. The patch is saved to /tmp/ai_generated_patch.sh
#   and then handed to safe_heal.sh for 5-layer validation before execution.
#
# Why local LLM (Ollama)?
#   A self-healing OS deployed in offline or embedded environments (remote
#   servers, spacecraft, edge devices) cannot rely on cloud AI APIs. Ollama
#   runs entirely on the host machine with no internet connection required
#   after the initial model download.
#
# Model: llama3.2 (3.2B parameters, Q4_K_M quantization, ~2GB RAM)
#   - Sufficient for generating short shell scripts
#   - Runs on consumer hardware (tested on 16GB RAM Windows host)
#   - temperature: 0.1 — near-deterministic output, consistent patches
#
# Network: Ollama runs on Windows host (10.0.2.2:11434 from Alpine VM)
#   10.0.2.2 is the VirtualBox NAT gateway — always the Windows host IP.
#
# Key research findings from Phase 3 testing:
#
# FINDING 1 — Prompt engineering is safety-critical:
#   Attempt 1 (open-ended prompt) generated a patch that stopped sshd,
#   wiped /var/tmp, and tried to install a non-existent package (hallucination).
#   Attempt 2 (constrained prompt) generated a correct, minimal, safe patch.
#   The model did not change — only the prompt changed. This demonstrates
#   that prompt design is a safety decision, not a cosmetic one.
#
# FINDING 2 — LLM hallucination is a concrete risk:
#   Attempt 1 included "apk add disk-cleaner" — a package that does not
#   exist in Alpine repositories. The model invented a plausible name.
#   This is concrete evidence that AI output cannot be trusted without
#   the 5-layer safety pipeline (Layer 1 caught it before execution).
#
# FINDING 3 — Executor log circular dependency (resolved):
#   The original executor.sh wrote its log to /tmp/executor_output.log.
#   When /tmp is full, this log file cannot be created — another instance
#   of the sandbox partition dependency problem from Phase 2.
#   Fix: executor log moved to /var/tmp/executor_output.log.
#
# Exit codes:
#   0  — patch generated successfully, saved to OUTPUT_PATCH
#   1  — failed (no Ollama response, empty patch, extraction error)
# =============================================================================

FAILURE_TYPE="$1"
OLLAMA_HOST="10.0.2.2:11434"
MODEL="llama3.2"
OUTPUT_PATCH="/tmp/ai_generated_patch.sh"

echo "============================================"
echo "[AI ENGINE] Starting patch generation"
echo "[AI ENGINE] Failure: $FAILURE_TYPE"
echo "[AI ENGINE] Model: $MODEL at $OLLAMA_HOST"
echo "============================================"

# ── Collect system context ────────────────────────────────────────────────────
DISK_TMP=$(df /tmp | awk 'NR==2{print $5}' | tr -d '%')
DISK_ROOT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
MEM_INFO=$(free -h 2>/dev/null)
OS_INFO=$(cat /etc/alpine-release 2>/dev/null)

echo "[AI ENGINE] System context collected"
echo "[AI ENGINE] /tmp usage: ${DISK_TMP}%"
echo "[AI ENGINE] / usage: ${DISK_ROOT}%"

# ── Build prompt ──────────────────────────────────────────────────────────────
# The prompt is the primary safety control at the AI level.
# Explicit prohibitions and allowances are required — an open-ended prompt
# causes the model to generate dangerous or hallucinated commands.
PROMPT="You are a shell script generator for Alpine Linux emergency repair.

FAILURE: $FAILURE_TYPE
SYSTEM: Alpine Linux $OS_INFO with OpenRC init system
/tmp usage: ${DISK_TMP}% (tmpfs, 483MB RAM-backed, SEPARATE from root disk)
/ usage: ${DISK_ROOT}%

GENERATE A SHELL SCRIPT that fixes $FAILURE_TYPE.

ABSOLUTE RULES — breaking any rule makes the patch useless:
- Start with EXACTLY: #!/bin/sh  (first line, nothing before it)
- End with EXACTLY: echo \"PATCH_COMPLETE\"  (last line)
- NO markdown, NO backticks, NO explanation, NO comments starting with #
- DO NOT stop or restart sshd — the operator connects via SSH
- DO NOT use systemctl — Alpine uses rc-service
- DO NOT install packages — no apk add commands
- DO NOT use rm -rf on any path — too dangerous
- DO NOT touch /var/tmp — system infrastructure lives there
- ONLY delete files in /tmp using: find /tmp -type f -delete
- ONLY clean apk cache using: rm -rf /var/cache/apk/*
- Maximum 10 lines total

For DISK_FULL: clean /tmp files and apk cache only.
For SERVICE_CRASH: use rc-service <name> start only.
For DEVICE_ERROR: use mount command to remount only.

Output the script now, nothing else:"

echo "[AI ENGINE] Sending request to Ollama..."

# ── Call Ollama API ───────────────────────────────────────────────────────────
RESPONSE=$(curl -s \
    --connect-timeout 10 \
    --max-time 120 \
    -X POST "http://$OLLAMA_HOST/api/generate" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": $(echo "$PROMPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
        \"stream\": false,
        \"options\": {
            \"temperature\": 0.1,
            \"num_predict\": 300
        }
    }" 2>/dev/null)

if [ -z "$RESPONSE" ]; then
    echo "[AI ENGINE] FAILED: No response from Ollama"
    echo "[AI ENGINE] Check Ollama is running: ollama serve"
    echo "[AI ENGINE] Check host reachable: curl http://$OLLAMA_HOST"
    exit 1
fi

echo "[AI ENGINE] Response received"

# ── Extract and clean patch from JSON response ────────────────────────────────
PATCH=$(echo "$RESPONSE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    text = data.get('response', '').strip()
    lines = text.split('\n')
    clean = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('\`\`\`'):
            continue
        clean.append(line)
    result = '\n'.join(clean).strip()
    print(result)
except Exception as e:
    print('')
")

if [ -z "$PATCH" ]; then
    echo "[AI ENGINE] FAILED: Could not extract patch from response"
    exit 1
fi

# ── Ensure shebang is present (add if AI omitted it) ─────────────────────────
FIRST=$(echo "$PATCH" | head -1)
if [ "$FIRST" != "#!/bin/sh" ]; then
    echo "[AI ENGINE] WARNING: Adding missing shebang"
    PATCH="#!/bin/sh
$PATCH"
fi

# ── Save patch ────────────────────────────────────────────────────────────────
echo "$PATCH" > "$OUTPUT_PATCH"
chmod +x "$OUTPUT_PATCH"

echo "[AI ENGINE] Patch saved to $OUTPUT_PATCH"
echo "[AI ENGINE] --- Generated patch ---"
cat "$OUTPUT_PATCH"
echo "[AI ENGINE] --- End patch ---"
echo "============================================"
exit 0
