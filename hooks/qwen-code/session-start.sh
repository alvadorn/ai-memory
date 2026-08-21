#!/bin/sh
# Qwen Code SessionStart hook.
# 1. Forwards the event JSON to the ai-memory server (fire-and-forget).
# 2. Synchronously fetches the pending cross-agent handoff and prints it
#    to stdout as structured JSON — Qwen Code parses SessionStart hook
#    stdout as JSON and injects `hookSpecificOutput.additionalContext`
#    into the session (verified against v0.21.14), so the resuming agent
#    sees prior context with no human in the loop.
#
# Walks up from the payload's cwd for a .ai-memory.toml marker file
# and appends cwd plus marker query params to both URLs — so a session
# resuming under basename or marker-declared routing doesn't query the
# wrong bucket and miss its own handoff.
# At runtime (after `install-hooks --apply`) `_lib.sh` is staged
# alongside this script. From the source tree it lives one dir up.
_lib_dir="$(dirname "$0")"
[ -f "$_lib_dir/_lib.sh" ] || _lib_dir="$_lib_dir/.."
. "$_lib_dir/_lib.sh"

SERVER="${AI_MEMORY_HOOK_URL:-http://127.0.0.1:49374}"
PAYLOAD=$(cat)
CWD=$(ai_memory_extract_cwd "$PAYLOAD")
QS=$(ai_memory_marker_qs "$CWD")
SESSION_ID=$(ai_memory_extract_session_id "$PAYLOAD")
SESSION_QS=""
[ -n "$SESSION_ID" ] && SESSION_QS="&session_id=$(ai_memory_url_encode "$SESSION_ID")"

printf '%s' "$PAYLOAD" \
    | ai_memory_post_hook "$SERVER/hook?event=session-start&agent=qwen-code${QS}" >/dev/null 2>&1 || true

# Qwen Code parses hook stdout as JSON on exit 0 and consumes
# `hookSpecificOutput.additionalContext` as session context; no handoff
# -> "{}" (empty stdout would also work, but the explicit JSON envelope
# keeps the debug log clean).
HANDOFF=$(ai_memory_get_handoff "$SERVER/handoff?agent=qwen-code${QS}${SESSION_QS}" 2>/dev/null || true)
if [ -n "$HANDOFF" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' \
        "$(printf '%s' "$HANDOFF" | ai_memory_json_string)"
else
    printf '{}\n'
fi
exit 0
