# TODO: Simplify the replacement of \ with / since NormalizePath does it for us
function Update-GitConfig {
    [CmdletBinding()]
    param()

    Pout -Level Debug -Message "Starting git configuration update"

    #{ Check if DOTS is set
    if (-not $env:DOTS) {
        Pout -Level Warn -Message "DOTS environment variable not set, skipping git configuration update"
        return $false
    }

    $mainGitConfigPath = Join-Path -Path $env:DOTS -ChildPath 'Configuration/git/main.gitconfig'
    $dotsGitConfig = & NormalizePath $mainGitConfigPath

    #{ Check if main gitconfig exists
    if (-not (Test-Path -Path $dotsGitConfig -PathType Leaf)) {
        Pout -Level Warn -Message "Main gitconfig not found at: $dotsGitConfig"
        return $false
    }

    Pout -Level Debug -Message "Updating git configuration to include: $dotsGitConfig"

    $gitConfigPath = Join-Path -Path $env:USERPROFILE -ChildPath '.gitconfig'

    #{ Create .gitconfig if it doesn't exist
    if (-not (Test-Path -Path $gitConfigPath)) {
        Pout -Level Info -Message "Creating new .gitconfig at: $gitConfigPath"
        New-Item -Path $gitConfigPath -ItemType File -Force | Out-Null
    }

    try {
        #{ Read current gitconfig content
        $gitConfigContent = if (Test-Path -Path $gitConfigPath) {
            Get-Content -Path $gitConfigPath -Raw
        }
        else {
            ""
        }

        #{ Check if the main.gitconfig is already included
        # $normalizedMainPath = $dotsGitConfig -replace '\\', '/'
        $isAlreadyIncluded = $false

        if ($gitConfigContent -match "path\s*=\s*.*main\.gitconfig") {
            #{ Check if it's specifically our main.gitconfig
            $existingPaths = $gitConfigContent | Select-String -Pattern "path\s*=\s*(.+)" -AllMatches
            foreach ($match in $existingPaths.Matches) {
                $existingPath = $match.Groups[1].Value.Trim() -replace '\\', '/'
                if ($existingPath -eq $normalizedMainPath -or $existingPath -like '*main.gitconfig') {
                    $isAlreadyIncluded = $true
                    break
                }
            }
        }

        #{ If already included, no need to modify
        if ($isAlreadyIncluded) {
            Pout -Level Debug -Message "Main gitconfig already included, no changes needed"
            return $true
        }

        #{ Parse the gitconfig to remove any existing includes to main.gitconfig and add ours
        $lines = $gitConfigContent -split "`r?`n"
        $newLines = @()
        $inIncludeSection = $false
        $hasIncludeSection = $false
        $includeEndIndex = -1

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]

            if ($line -match '^\[include\]') {
                $inIncludeSection = $true
                $hasIncludeSection = $true
                $newLines += $line
            }
            elseif ($line -match '^\[.*\]' -and $line -notmatch '^\[include\]') {
                #{ Mark where include section ends
                if ($inIncludeSection) {
                    $includeEndIndex = $newLines.Count
                }
                $inIncludeSection = $false
                $newLines += $line
            }
            elseif ($inIncludeSection -and $line -match '^\s*path\s*=\s*(.+)') {
                $path = $matches[1].Value.Trim()
                #{ Skip if it points to any main.gitconfig
                if ($path -notlike '*main.gitconfig' -and $path -notlike '*/main.gitconfig') {
                    $newLines += $line
                }
                #{ Note: we skip adding main.gitconfig entries here
            }
            else {
                $newLines += $line
            }
        }

        #{ Add include section if it doesn't exist
        if (-not $hasIncludeSection) {
            $newLines += '[include]'
            $newLines += "`tpath = $dotsGitConfig"
        }
        else {
            #{ Insert the path at the end of the include section
            if ($includeEndIndex -gt 0) {
                #{ Insert before the next section
                $newLines = $newLines[0..($includeEndIndex - 1)] + "`tpath = $dotsGitConfig" + $newLines[$includeEndIndex..($newLines.Length - 1)]
            }
            else {
                #{ Add at the end (include section was the last section)
                $newLines += "`tpath = $dotsGitConfig"
            }
        }

        #{ Write the updated content back to the file
        $newContent = ($newLines | Where-Object { $_ -ne $null }) -join "`n"
        Set-Content -Path $gitConfigPath -Value $newContent -NoNewline

        Pout -Level Info -Message "Successfully updated git configuration"
        Pout -Level Debug -Message "Added include path: $dotsGitConfig"

        return $true
    }
    catch {
        Pout -Level Error -Message "Failed to update git configuration: $($_.Exception.Message)"
        return $false
    }
}

# Update-GitConfig
