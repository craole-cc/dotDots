# Links.psm1 - Main module file

# Get the module root path
$ModuleRoot = $PSScriptRoot

# Import private functions
$PrivateFunctions = Get-ChildItem -Path "$ModuleRoot\Internal\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
  try {
    . $Function.FullName
    Write-Pretty -NoNewLine -Tag 'Trace' "Imported private function: $($Function.BaseName)"
  }
  catch {
    Write-Pretty -NoNewLine -Tag 'Error' "Failed to import private function $($Function.BaseName): $($_.Exception.Message)"
  }
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path "$ModuleRoot\External\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
  try {
    . $Function.FullName
    Write-Pretty -NoNewLine -Tag 'Trace' "Imported public function: $($Function.BaseName)"
  }
  catch {
    Write-Pretty -NoNewLine -Tag 'Error' "Failed to import public function $($Function.BaseName): $($_.Exception.Message)"
  }
}

# Export public functions
$PublicFunctionNames = $PublicFunctions | ForEach-Object { $_.BaseName }
Export-ModuleMember -Function $PublicFunctionNames

# Module initialization
Write-Pretty -NoNewLine -Tag 'Trace' 'Links module loaded successfully'
