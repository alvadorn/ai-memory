#!/bin/sh
# Qwen Code stop hook.
# Forwards the event JSON to the ai-memory server, fire-and-forget.
# Assistant/Stop capture (#196) is native-only: the script fallback cannot
# sanitize the assistant message, so if the raw payload still carries the field
# we drop the whole Stop rather than POST it verbatim. A literal substring check
# (POSIX `case`, no bash-isms per _lib.sh) — conservative on purpose: any Stop
# mentioning the key is dropped. Move to a native install to capture it safely.
_lib_dir="$(dirname "$0")"
[ -f "$_lib_dir/_lib.sh" ] || _lib_dir="$_lib_dir/.."
. "$_lib_dir/_lib.sh"

SERVER="${AI_MEMORY_HOOK_URL:-http://127.0.0.1:49374}"
PAYLOAD=$(cat)
case "$PAYLOAD" in
    *'"last_assistant_message"'*)
        printf '{}\n'
        exit 0
        ;;
esac
CWD=$(ai_memory_extract_cwd "$PAYLOAD")
QS=$(ai_memory_marker_qs "$CWD")

printf '%s' "$PAYLOAD" \
    | ai_memory_post_hook "$SERVER/hook?event=stop&agent=qwen-code${QS}" >/dev/null 2>&1 || true
# Acknowledge with an empty JSON object (Qwen Code parses stdout as
# JSON on exit 0; plain text is only handled as a debug fallback).
printf '{}\n'
exit 0
