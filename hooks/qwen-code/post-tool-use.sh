#!/bin/sh
# Qwen Code post-tool-use hook.
# Forwards the event JSON to the ai-memory server, fire-and-forget.
# Qwen Code fires PostToolUse only on successful tool calls and reports
# failures separately as PostToolUseFailure, which reuses this script
# (the server reads the outcome from the payload).
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
    | ai_memory_post_hook "$SERVER/hook?event=post-tool-use&agent=qwen-code${QS}" >/dev/null 2>&1 || true
# Acknowledge with an empty JSON object (Qwen Code parses stdout as
# JSON on exit 0; plain text is only handled as a debug fallback).
printf '{}\n'
exit 0
