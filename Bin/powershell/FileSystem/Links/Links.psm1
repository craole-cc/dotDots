# Links.psm1 - Main module file

# Get the module root path
$ModuleRoot = $PSScriptRoot

# Import private functions
$PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
  try {
    . $Function.FullName
    Write-Verbose "Imported private function: $($Function.BaseName)"
  }
  catch {
    Write-Error "Failed to import private function $($Function.BaseName): $($_.Exception.Message)"
  }
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
  try {
    . $Function.FullName
    Write-Verbose "Imported public function: $($Function.BaseName)"
  }
  catch {
    Write-Error "Failed to import public function $($Function.BaseName): $($_.Exception.Message)"
  }
}

# Export public functions
$PublicFunctionNames = $PublicFunctions | ForEach-Object { $_.BaseName }
Export-ModuleMember -Function $PublicFunctionNames

# Module initialization
Write-Verbose 'Links module loaded successfully'
