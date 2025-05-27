<#
.SYNOPSIS
    Function to change directory to DOTS - defined globally
#>
function Global:Set-LocationDots {
    if ($env:DOTS -and (Test-Path $env:DOTS)) {
        Set-Location $env:DOTS
        Write-Host "📁 Changed to DOTS directory: $env:DOTS" -ForegroundColor Green
    } else {
        Write-Warning "DOTS directory not found or not set"
    }
}

<#
.SYNOPSIS
    Function to open DOTS in default editor - defined globally
#>
function Global:Edit-DotsDirectory {
    if ($env:DOTS -and (Test-Path $env:DOTS)) {
        #@ Try common editors in order of preference
        $editors = @(
            @{ Name = 'code'; Args = @($env:DOTS) },                    #? VS Code
            @{ Name = 'code-insiders'; Args = @($env:DOTS) },           #? VS Code Insiders
            @{ Name = 'hx'; Args = @($env:DOTS) },                      #? Helix
            @{ Name = 'subl'; Args = @($env:DOTS) },                    #? Sublime Text
            @{ Name = 'atom'; Args = @($env:DOTS) },                    #? Atom
            @{ Name = 'notepad++'; Args = @($env:DOTS) },               #? Notepad++
            @{ Name = 'explorer'; Args = @($env:DOTS) }                 #? File Explorer as fallback
        )

        $editorFound = $false
        foreach ($editor in $editors) {
            try {
                $command = Get-Command $editor.Name -ErrorAction SilentlyContinue
                if ($command) {
                    Write-Host "🚀 Opening DOTS in $($editor.Name): $env:DOTS" -ForegroundColor Green
                    & $editor.Name @($editor.Args)
                    $editorFound = $true
                    break
                }
            } catch {
                continue
            }
        }

        if (-not $editorFound) {
            Write-Warning "No suitable editor found. Opening in File Explorer..."
            explorer $env:DOTS
        }
    } else {
        Write-Warning "DOTS directory not found or not set"
    }
}

<#
.SYNOPSIS
    Creates convenient aliases and functions for working with DOTS.
#>
function Set-DotsAliases {
    [CmdletBinding()]
    param()

    if (-not $env:DOTS) {
        Write-Message -Level Warn -Message "DOTS not configured, skipping alias creation"
        return
    }

    #@ Create aliases with explicit global scope
    Set-Alias -Name 'cd.dots' -Value Set-LocationDots -Scope Global -Force
    Set-Alias -Name 'edit.dots' -Value Edit-DotsDirectory -Scope Global -Force
    Set-Alias -Name 'dots' -Value Set-LocationDots -Scope Global -Force
    Set-Alias -Name 'open.dots' -Value Edit-DotsDirectory -Scope Global -Force

    Write-Message -Level Debug -Message "DOTS aliases created: cd.dots, edit.dots, dots, open.dots"
}
