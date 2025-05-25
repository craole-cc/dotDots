# $Context = "importDOTS"

#@ Define module directories and their types
$ModuleTypes = @{
    # "functions" = "Function"
    "modules" = "Module"
}


function importDOTS {
    [CmdletBinding()]
    param()
    #@ Load each type of module
    foreach ($type in $ModuleTypes.GetEnumerator()) {
        $moduleHome = & NormalizePath (Join-Path $PSScriptRoot $type.Key)

        if (-not (Test-Path $moduleHome)) {
            Pout `
                -Level "Warn" `
                -Context "LoadModules" `
                -Message "Module directory not found: $moduleHome"
            continue
        }

        if (Test-Path $moduleHome) {
            Get-ChildItem -Path $moduleHome -Filter "*.ps1" -Recurse | ForEach-Object {
                try {
                    . $_.FullName
                }
                catch {
                    Pout `
                        -Level "Error" `
                        "Failed to load $($type.Value): $($_.BaseName)" `
                        "Error: $($_.Exception.Message)" `

                }
            }
        }
        else {
            Pout `
                -Level "Warn" `
                -Context "LoadModules" `
                -Message "Module directory not found: $moduleHome"
        }
    }
}

RunCommand importDOTS

