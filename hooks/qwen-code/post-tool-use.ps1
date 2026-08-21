. "$PSScriptRoot\..\lib\ai-memory-hook.ps1"
Invoke-AiMemoryHook -Event "post-tool-use" -Agent "qwen-code"
exit 0
