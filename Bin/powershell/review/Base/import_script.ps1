function Import-Script {
    <#
    .SYNOPSIS
    Imports scripts or folders from a specified root path with flexible loading logic.

    .DESCRIPTION
    For each item in the list:
    - If the item ends with '.ps1', treat it as an explicit script path and load directly.
    - Otherwise, treat it as a folder name under the current root path:
        - If the folder contains a _.ps1 file, load that file.
        - Otherwise, load all .ps1 files in that folder.
    - If the folder does not exist, look for a script file named <item>.ps1 in the current root path and load it if found.
    When dot-sourcing scripts, nested Import-Script calls will use the directory of the calling script as the default root.
    Writes verbose output on success, warnings if files/folders are missing, and errors if loading fails.

    .PARAMETER ScriptItems
    An ordered array of folder names or script file base names to import.

    .PARAMETER RootPath
    The root directory path where the script files are located.
    - If not specified, automatically uses the directory of the calling script
    - Use this parameter to explicitly specify a different starting directory
    - Useful for loading scripts from a different location than the caller's directory

    .EXAMPLE
    # Load scripts from the same directory as the calling script (automatic detection)
    Import-Script -ScriptItems @('output', 'command', 'context')

    .EXAMPLE
    # Load scripts from a specific directory
    Import-Script -ScriptItems @('utils', 'helpers') -RootPath 'C:\MyScripts\Common'

    .EXAMPLE
    # Load scripts from a relative path
    Import-Script -ScriptItems @('shared') -RootPath '..\SharedModules'
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptItems,

        [string]$RootPath
    )

    # If no RootPath provided, determine it from the calling script
    if (-not $RootPath) {
        $callingScript = (Get-PSCallStack)[1].ScriptName
        if ($callingScript) {
            $RootPath = Split-Path -Parent $callingScript
        } else {
            $RootPath = $PSScriptRoot
        }
    }

    foreach ($item in $ScriptItems) {
        # If item ends with '.ps1', treat as explicit path and load directly
        if ($item -like '*.ps1') {
            $explicitPath = if ([System.IO.Path]::IsPathRooted($item)) {
                $item
            }
            else {
                Join-Path $RootPath $item
            }

            if (Test-Path $explicitPath) {
                try {
                    . $explicitPath
                    Write-Verbose "Initialized script: $explicitPath"
                }
                catch {
                    Write-Error "Failed to load $explicitPath`: $_"
                }
            }
            else {
                Write-Warning "Explicit script file not found: $explicitPath"
            }
            continue
        }

        # Otherwise, treat as folder or script base name
        $folderPath = Join-Path $RootPath $item
        $fileInFolder = Join-Path $folderPath '_.ps1'
        $fileAtRoot = Join-Path $RootPath "$item.ps1"

        if (Test-Path $folderPath -PathType Container) {
            if (Test-Path $fileInFolder) {
                try {
                    . $fileInFolder
                    Write-Verbose "Initialized script: $item\_.ps1"
                    Write-Host "[Trace] "
                }
                catch {
                    Write-Error "Failed to load $item\_.ps1`: $_"
                }
            }
            else {
                $ps1Files = Get-ChildItem -Path $folderPath -Filter '*.ps1' -File | Sort-Object Name
                if ($ps1Files.Count -gt 0) {
                    foreach ($file in $ps1Files) {
                        try {
                            . $file.FullName
                            Write-Verbose "Initialized script: $($item)\$($file.Name)"
                            Write-Host "[TRACE] Initialized script: $($item)\$($file.Name)"
                        }
                        catch {
                            Write-Error "Failed to load $($file.Name): $_"
                            Write-Host "[ERROR] Failed to load $($file.Name): $_"
                        }
                    }
                }
                else {
                    Write-Warning "No scripts found in folder: $folderPath"
                    Write-Host "[WARN] No scripts found in folder: $folderPath"
                }
            }
        }
        elseif (Test-Path $fileAtRoot) {
            try {
                . $fileAtRoot
                Write-Verbose "Initialized script: $item.ps1"
                Write-Host "[TRACE] Initialized script: $item.ps1"
            }
            catch {
                Write-Error "Failed to load $item.ps1`: $_"
                Write-Host "[TRACE] Failed to load $item.ps1`: $_"
            }
        }
        else {
            Write-Warning "Neither folder nor script file found for: $item"
            Write-Host "[TRACE] Neither folder nor script file found for: $item"
        }
    }
}
