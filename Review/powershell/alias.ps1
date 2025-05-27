# Set your preferred editor (or use $env:VISUAL/$env:EDITOR if set)
$defaultEditor = $env:VISUAL ?? $env:EDITOR ?? 'code'

# Loop through all environment variables
foreach ($envVar in [System.Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
  $name = $envVar.Key
  $value = $envVar.Value

  # Skip empty values
  if ([string]::IsNullOrWhiteSpace($value)) { continue }

  # Create 'cd.*' alias if it's a directory
  if (Test-Path $value -PathType Container) {
    $cdAlias = "cd.$name"
    Set-Alias -Name $cdAlias -Value (Join-Path $PSScriptRoot "GoTo-EnvDir.ps1") -Option AllScope -Force

    # Define a function for the alias to actually 'cd' to the directory
    $cdFunc = @"
function global:$cdAlias {
    Set-Location -Path '$value'
}
"@
    Invoke-Expression $cdFunc
  }

  # Create 'edit.*' alias for both files and directories
  if (Test-Path $value) {
    $editAlias = "edit.$name"
    $editFunc = @"
function global:$editAlias {
    `$editor = `$env:VISUAL ?? `$env:EDITOR ?? '$defaultEditor'
    & `$editor '$value'
}
"@
    Invoke-Expression $editFunc
  }
}
