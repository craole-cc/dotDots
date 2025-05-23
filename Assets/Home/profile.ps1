#Requires -Version 5.1

#region Settings

#@ Global script variables - explicitly set in global scope
$Global:VerbosityLevel = @{
    'Quiet' = 0; 'Error' = 1; 'Warn' = 2; 'Info' = 3; 'Debug' = 4; 'Trace' = 5
}['Trace']

#endregion

#region Utilities

function Global:Exec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $startTime = Get-Date

    Pout -Level "Trace" -Message "Execution started at $startTime" -Context $Command
    if ($Arguments) {
        Pout -Level "Trace" -Message "Arguments: $($Arguments -join ', ')"
    }

    try {
        #@ Execute the command with verbosity from global setting
        $result = & $Command

        if ($Global:VerbosityLevel -ge 4) {
            $duration = (Get-Date) - $startTime
            $durationMs = [math]::Round($duration.TotalMilliseconds)
            Pout -Level "Trace" -Message "Command completed in ${durationMs}ms" -CustomContext $Command
        }

        return $result
    }
    catch {
        $duration = (Get-Date) - $startTime
        $durationMs = [math]::Round($duration.TotalMilliseconds)
        Pout -Level "Error" -Message "Command failed after ${durationMs}ms: $($_.Exception.Message)" -CustomContext $Command
        throw
    }
}

function Global:Pout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('msg')]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Trace', 'Debug', 'Info', 'Warn', 'Error')]
        [Alias('tag', 'lvl', 'log')]
        [string]$Level = $Global:VerbosityLevel,

        [Parameter()]
        [switch]$Timestamp,

        [Parameter()]
        [string]$Context,

        [Parameter()]
        [Alias('As', 'For', 'ctx')]
        [string]$CustomContext,

        [Parameter()]
        [Alias('Time')]
        [switch]$Measure
    )

    if ($Measure) {
        $startTime = Get-Date
    }

    $levelMap = @{
        'Trace' = @{ Number = 5; Color = 'Magenta'; Tag = 'TRACE' }
        'Debug' = @{ Number = 4; Color = 'Cyan'; Tag = 'DEBUG' }
        'Info'  = @{ Number = 3; Color = 'Blue'; Tag = ' INFO' }
        'Warn'  = @{ Number = 2; Color = 'Yellow'; Tag = ' WARN' }
        'Error' = @{ Number = 1; Color = 'Red'; Tag = 'ERROR' }
    }
    $currentLevel = $levelMap[$Level]



    #@ Get context based on priority: CustomContext > Context > Auto-detected
    $displayContext = if (-not [string]::IsNullOrEmpty($CustomContext)) {
        $CustomContext
    }
    elseif (-not [string]::IsNullOrEmpty($Context)) {
        $Context
    }
    else {
        $callStack = Get-PSCallStack
        if ($callStack.Count -gt 1) {
            $caller = $callStack[1]
            if (-not [string]::IsNullOrEmpty($caller.FunctionName)) {
                $caller.FunctionName
            }
            else {
                $caller.Command
            }
        }
    }

    #@ Build the message components
    $components = @()

    if ($Timestamp) {
        $components += Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    $components += $currentLevel.Tag

    if (-not [string]::IsNullOrEmpty($displayContext)) {
        $tagHead = ">>-"
        $tagTail = "->>"
        $components += "$tagHead $displayContext $tagTail"
    }

    if ($Measure) {
        $duration = (Get-Date) - $startTime
        $durationMs = [math]::Round($duration.TotalMilliseconds)
        $Message = "$Message (${durationMs}ms)"
    }

    $components += $Message

    #@ Output the message
    $fullMessage = $components -join ' '
    Write-Host $fullMessage -ForegroundColor $currentLevel.Color
}

#region DOTS
function locateDOTS {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Parents = @(
            'D:/Projects/GitHub/CC',
            'D:/Configuration',
            'D:/Dotfiles',
            $env:USERPROFILE
        ),

        [Parameter()]
        [string[]]$Targets = @(
            '.dots',
            'dotDots',
            'dots',
            'dotfiles',
            'global',
            'config',
            'common'
        ),

        [Parameter()]
        [string[]]$Markers = @(
            '.dotsrc',
            '.git',
            '.flake.nix',
            'flake.nix'
        )
    )

    Pout -lvl Trace -msg "Starting DOTS directory search"

    #@ Ensure arrays for input parameters
    $Parents = @($Parents)
    $Targets = @($Targets)
    $Markers = @($Markers)

    Pout -Level "Debug" -Message "Parents: $($Parents -join ', ')"
    Pout -Level "Debug" -Message "Targets: $($Targets -join ', ')"
    Pout -Level "Debug" -Message "Markers: $($Markers -join ', ')"

    foreach ($parent in $Parents) {
        if (-not (Test-Path -Path $parent -PathType Container)) { continue }

        foreach ($dirName in $Targets) {
            $dotsPath = Join-Path -Path $parent -ChildPath $dirName
            if (-not (Test-Path -Path $dotsPath -PathType Container)) { continue }

            #@ Check if any of the marker files exist
            foreach ($child in $Markers) {
                $markerPath = Join-Path -Path $dotsPath -ChildPath $child
                if (Test-Path -Path $markerPath -PathType Leaf) {
                    Pout -Level "Debug" -Message "Found '$child' in: $dotsPath"

                    #@ Set DOTS in all scopes
                    [Environment]::SetEnvironmentVariable('DOTS', $dotsPath, 'Process')
                    $Global:DOTS = $dotsPath
                    Set-Item -Path 'env:DOTS' -Value $dotsPath

                    Pout -Level "Info" -Message "DOTS environment set to: $Global:DOTS"
                    return $true
                }
            }
        }
    }

    Pout -Level "Warn" -Message "No DOTS directory found"
    return $false
}

function importDOTS {
    [CmdletBinding()]
    param()

    try {
        if (-not $env:DOTS) {
            #@ Locate the DOTS directory using the default parameters
            $found = locateDOTS
            if (-not $found) {
                throw "Failed to locate DOTS directory"
            }

            if (-not $found) {
                Pout -Level "Warn" -Message "Failed to locate DOTS directory"
                return $false
            }

            Pout -Level "Trace" -Message "DOTS directory found: $env:DOTS"

        }

        #@ Load the PowerShell profile from the DOTS directory
        $profilePath = Join-Path $env:DOTS 'Configuration/powershell/profile.ps1'
        if (-not (Test-Path -Path $profilePath -PathType Leaf)) {
            throw "PowerShell profile not found: $profilePath"
        }

        Pout -Level "Info" -Message "Loading profile"
        . $profilePath
    }
    catch {
        Pout -Level "Error" -Message $_.Exception.Message
        return $false
    }
}
#endregion

#region Main Execution

Exec importDOTS

#endregion
