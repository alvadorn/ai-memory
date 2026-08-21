. "$PSScriptRoot\..\lib\ai-memory-hook.ps1"
Invoke-AiMemoryHook -Event "session-start" -Agent "qwen-code" -FetchHandoff
exit 0
