# $Context = "importDOTS"

# #@ Define module directories and their types
$ModuleTypes = @{
    "functions" = "Function"
    "modules"   = "Module"
}


#@ Load each type of module
foreach ($type in $ModuleTypes.GetEnumerator()) {
    $path = Join-Path $PSScriptRoot $type.Key

    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter "*.ps1" -Recurse | ForEach-Object {
            try {
                # Exec $_.FullName
                Pout -Level "Info" -Scope "Path" -Message "      Loading $($type.Value): $($_.BaseName)" -HideContext -HideVerbosity
                . $_.FullName
            }
            catch {
                Pout -Level "Error" -Message "      Failed to load $($type.Value): $($_.BaseName)`nError: $($_.Exception.Message)"
            }
        }
    }
    else {
        Pout -Level "Warning" -Message "  ! $($type.Value) Path not found: $($_.BaseName)"
    }
}
Write-Host "I'm here"
