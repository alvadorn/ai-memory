#!/bin/sh
# Qwen Code session-end hook.
# Forwards the event JSON to the ai-memory server, fire-and-forget.
# Note: in headless `qwen -p` runs (v0.21.14) SessionEnd did not fire;
# the interactive TUI does. If a session's tail stays open, close it
# with `ai-memory finalize-session --agent qwen-code`.
# Walks up from the payload's cwd for a .ai-memory.toml marker file;
# if found, appends marker query params to the URL so the server
# applies the declared workspace/project/strategy instead of
# bucketing by basename(cwd) under the default workspace.
# At runtime (after `install-hooks --apply`) `_lib.sh` is staged
# alongside this script. From the source tree it lives one dir up.
_lib_dir="$(dirname "$0")"
[ -f "$_lib_dir/_lib.sh" ] || _lib_dir="$_lib_dir/.."
. "$_lib_dir/_lib.sh"

SERVER="${AI_MEMORY_HOOK_URL:-http://127.0.0.1:49374}"
PAYLOAD=$(cat)
CWD=$(ai_memory_extract_cwd "$PAYLOAD")
QS=$(ai_memory_marker_qs "$CWD")

printf '%s' "$PAYLOAD" \
    | ai_memory_post_hook "$SERVER/hook?event=session-end&agent=qwen-code${QS}" >/dev/null 2>&1 || true
# Acknowledge with an empty JSON object (Qwen Code parses stdout as
# JSON on exit 0; plain text is only handled as a debug fallback).
printf '{}\n'
exit 0
