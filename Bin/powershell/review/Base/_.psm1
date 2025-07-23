# . $PSScriptRoot\import_script.ps1

# Import-Script @(
#   'admin',
#   'command',
#   'context',
#   'filesystem',
#   'time',
#   'output',
#   'types'
# )

# # Debug: Check what functions are available in current scope
# Write-Host "=== DEBUGGING MODULE EXPORTS ===" -ForegroundColor Cyan
# Write-Host "Functions in current scope:" -ForegroundColor Yellow
# Get-ChildItem Function: | Where-Object { $_.Name -in @('Write-Pretty', 'Test-WritePretty', 'Write-Pattern') } | Select-Object Name, Source | Format-Table

# Write-Host "All functions starting with Write-:" -ForegroundColor Yellow
# Get-ChildItem Function: | Where-Object { $_.Name -like 'Write-*' } | Select-Object Name, Source | Format-Table

# Write-Host "Current execution context:" -ForegroundColor Yellow
# Write-Host "MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
# Write-Host "PSScriptRoot: $PSScriptRoot"

# # Define aliases AFTER functions are loaded
# Set-Alias -Name pout -Value Write-Pattern

# # Export everything at the module level
# Export-ModuleMember -Function @(
#   'Write-Pretty',
#   'Test-WritePretty',
#   'Write-Pattern',
#   'Import-Script',  # Don't forget this if you want it exported
#   'Test-ImportScript'
# ) -Alias @(
#   'pout'
# ) -Variable @(
#   # Add any variables you want to export
# )
