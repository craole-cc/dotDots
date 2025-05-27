#@ Load functions
# . $PSScriptRoot/editor.ps1    # ← Load editor functions first
. $PSScriptRoot/variable.ps1     # ← Then load aliases (uses editor functions)
. $PSScriptRoot/alias.ps1     # ← Then load aliases (uses editor functions)
# . $PSScriptRoot/fyls.ps1

#@ Run tests
# Test-EnvVarAccess
# Show-EditorConfig             # From editor.ps1
# Show-PathAliases             # From alias.ps1
