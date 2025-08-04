# # Nuclear option - refresh all environment variables
# foreach ($level in 'Machine', 'User') {
#   [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
#     if ($_.Name -match 'Path$') {
#       $combined_path = (($combined_path + ";$($_.Value)") -replace '^;', '')
#     }
#     else {
#       $_
#     }
#   } | Set-Content env:\$($_.Name)
# }

# Get current system PATH
$currentPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')

# Add Cargo to system PATH (replace with your actual path if different)
$cargoPath = "$env:USERPROFILE\.cargo\bin"

# Check if it's already there
if ($currentPath -notlike "*$cargoPath*") {
  $newPath = $currentPath + ';' + $cargoPath
  [Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')
  Write-Info "Added $cargoPath to system PATH"
}
else {
  Write-Debug 'Cargo path already in system PATH'
}
