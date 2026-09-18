function Repair-BrokenLinks {
    <#
    .SYNOPSIS
    Attempts to repair broken links by updating their targets.

    .DESCRIPTION
    Scans a directory for broken links and attempts to repair them by looking for
    files with the same name in a new base path.

    .PARAMETER Directory
    The directory to scan for broken links.

    .PARAMETER NewBasePath
    The new base directory where target files might be located.

    .PARAMETER WhatIf
    Shows what would be repaired without actually making changes.

    .EXAMPLE
    Repair-BrokenLinks -Directory "C:\Links" -NewBasePath "C:\NewData"
    Attempts to repair broken links by looking for targets in the new path.

    .EXAMPLE
    Repair-BrokenLinks -Directory "C:\Links" -NewBasePath "C:\NewData" -WhatIf
    Shows what links would be repaired without making changes.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [string]$NewBasePath,

        [Parameter(Mandatory = $false)]
        [Alias('dry', 'dryrun', 'simulate')]
        [switch]$WhatIf
    )

    if (-not (Test-Path $Directory)) {
        Write-Error "Directory does not exist: $Directory"
        return
    }

    if (-not (Test-Path $NewBasePath)) {
        Write-Error "New base path does not exist: $NewBasePath"
        return
    }

    Write-Host "Scanning for broken links in: $Directory" -ForegroundColor Yellow

    $brokenLinks = Get-ChildItem $Directory -Recurse | Test-Link -Quiet |
                   Where-Object { $_.IsLink -and -not $_.IsValid }

    if ($brokenLinks.Count -eq 0) {
        Write-Host "No broken links found" -ForegroundColor Green
        return
    }

    Write-Host "Found $($brokenLinks.Count) broken links" -ForegroundColor Yellow

    $repairedCount = 0
    $unrepairedCount = 0

    foreach ($link in $brokenLinks) {
        $oldTarget = $link.Target
        $filename = Split-Path $oldTarget -Leaf
        $newTarget = Join-Path $NewBasePath $filename

        if (Test-Path $newTarget) {
            if ($WhatIf) {
                Write-Host "Would repair: $($link.Path) -> $newTarget" -ForegroundColor Yellow
                $repairedCount++
            }
            else {
                try {
                    Remove-Item $link.Path -Force
                    New-Item -ItemType SymbolicLink -Path $link.Path -Target $newTarget -Force | Out-Null
                    Write-Host "✓ Repaired: $(Split-Path $link.Path -Leaf) -> $newTarget" -ForegroundColor Green
                    $repairedCount++
                }
                catch {
                    Write-Error "Failed to repair $($link.Path): $($_.Exception.Message)"
                    $unrepairedCount++
                }
            }
        }
        else {
            Write-Warning "Cannot repair $(Split-Path $link.Path -Leaf): new target not found at $newTarget"
            $unrepairedCount++
        }
    }

    $actionText = if ($WhatIf) { "Would repair" } else { "Repaired" }
    Write-Host "`nRepair summary:" -ForegroundColor Yellow
    Write-Host "  $actionText`: $repairedCount links" -ForegroundColor Green
    Write-Host "  Cannot repair: $unrepairedCount links" -ForegroundColor Red
}
