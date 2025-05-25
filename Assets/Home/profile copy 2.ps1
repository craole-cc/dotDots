#Requires -Version 5.1

#region Settings
$Global:Verbosity = [Verbosity]::Trace
# $VerbosePreference = 'Continue'
# $DebugPreference = 'Continue'

#endregion

#region Types
enum Verbosity {
    Quiet = 0
    Error = 1
    Warn = 2
    Info = 3
    Debug = 4
    Trace = 5
}

class VerbosityManager {
    # Get color for verbosity level
    static [string] GetColor([Verbosity]$level) {
        return @{
            [Verbosity]::Quiet = 'Gray'
            [Verbosity]::Error = 'Red'
            [Verbosity]::Warn  = 'Yellow'
            [Verbosity]::Info  = 'Blue'
            [Verbosity]::Debug = 'Green'
            [Verbosity]::Trace = 'Magenta'
        }[$level]
    }

    # Get tag for verbosity level
    static [string] GetTag([Verbosity]$level) {
        return @{
            [Verbosity]::Quiet = 'QUIET '
            [Verbosity]::Error = 'ERROR '
            [Verbosity]::Warn  = 'WARN  '
            [Verbosity]::Info  = 'INFO  '
            [Verbosity]::Debug = 'DEBUG '
            [Verbosity]::Trace = 'TRACE '
        }[$level]
    }

    # Convert from various input types to Verbosity
    static [Verbosity] From($value) {
        if ($null -eq $value) {
            return $Global:Verbosity ?? [Verbosity]::Info
        }

        if ($value -is [Verbosity]) {
            return $value
        }

        if ($value -is [int] -or $value -match '^\d+$') {
            return [Verbosity]([Math]::Max(0, [Math]::Min(5, [int]$value)))
        }

        if ($value -is [string]) {
            $parsed = $null
            if ([System.Enum]::TryParse([Verbosity], $value.ToUpper(), [ref]$parsed)) {
                return $parsed
            }
        }

        return [Verbosity]::Info
    }
}

#endregion

#region Utilities

function GetContext {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Path', 'Name')]
        [string]$Scope,

        [Parameter()]
        [string]$Context,

        [Parameter()]
        [Management.Automation.CallStackFrame]$Caller = (Get-PSCallStack)[1]
    )

    #@ If Context scope is not provided, set defaults based on Verbosity enum
    if (-not $Scope) {
        $Scope = if ($Global:Verbosity -gt [Verbosity]::Info) {
            'Path'
        }
        else {
            'Name'
        }
    }

    #@ If no explicit context provided, try to get from caller
    if ([string]::IsNullOrEmpty($Context)) {
        $scriptPath = if ($Caller.ScriptName) {
            $fullPath = & NormalizePath $Caller.ScriptName
            switch ($Scope) {
                'Path' { $fullPath }
                'Name' { [System.IO.Path]::GetFileName($fullPath) }
            }
        }

        $functionName = if ($Caller.FunctionName -and -not ($Caller.FunctionName -match '^<.*>$')) {
            $Caller.FunctionName -replace '^Global:', ''
        }

        $position = if ($Caller.Position.StartLineNumber -gt 0) {
            ":$($Caller.Position.StartLineNumber):$($Caller.Position.StartColumnNumber)"
        }

        return $(if ($scriptPath -and $functionName) {
                "$scriptPath | $functionName$position"
            }
            elseif ($scriptPath) {
                "$scriptPath$position"
            }
            elseif ($functionName) {
                "$functionName$position"
            }
            else {
                'Console'
            })
    }

    # Use provided context if given
    return $Context
}

function Global:NormalizePath {
    [CmdletBinding()]
    param($path)

    $newPath = [System.IO.Path]::GetFullPath($path)
    $newPath = $path.Replace('\\', '/')
    $newPath = $path.Replace('\', '/')
    return $newPath
}

function Global:Pout {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('tag', 'level', 'lvl')]
        [ValidateScript({
                $_ -is [Verbosity] -or
                $_ -is [string] -or
            ($_ -is [int] -and $_ -ge 0 -and $_ -le 5)
            })]
        $Verbosity,

        [Parameter()]
        [Alias('as', 'for', 'of', 'ctx')]
        [string]$Context,

        [Parameter()]
        [ValidateSet('Path', 'Name')]
        [Alias('scope')]
        [string]$ContextScope,

        [Parameter()]
        [Alias('log')]
        [switch]$ShowTimestamp,

        [Parameter()]
        [Alias('noline')]
        [switch]$NoNewLine,

        [Parameter()]
        [Alias('time' , 'runtime')]
        [string]$Duration,

        [Parameter()]
        [Alias('noctx')]
        [switch]$HideContext,

        [Parameter()]
        [Alias('noverb')]
        [switch]$HideVerbosity,

        [Parameter()]
        [Alias('delim', 'separator', 'sep')]
        [string]$Delimiter = "`n === ", #? Default to newline + 4 spaces

        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        [Alias('msg')]
        [string[]]$Messages
    )

    #@ Ensure the verbosity level allows for output
    $VerbosityLocal = [Verbosity]::From($Verbosity)
    $VerbosityGlobal = [Verbosity]::From($Global:Verbosity)
    if ([int]$VerbosityLocal -gt [int]$VerbosityGlobal) { return }

    #@ If Context scope is not provided, set defaults based on Verbosity enum
    if (-not $ContextScope) {
        $ContextScope = switch ($VerbosityLocal) {
            [Verbosity]::Error { 'Path' }
            [Verbosity]::Debug { 'Path' }
            [Verbosity]::Trace { 'Path' }
            default { 'Name' }
        }
    }

    Write-Debug "Verbosity: $([Verbosity]::GetTag($VerbosityLocal))[$VerbosityLocal]"
    Write-Debug "Context: ${Context}"
    Write-Debug "ContextScope: $ContextScope"

    #@ Add timestamp if ShowTimestamp is set
    if ($ShowTimestamp)
    { $timestamp = Get-Date -Format '[yyyy-MM-dd HH:mm:ss] ' }
    else { $timestamp = '' }

    #@ Add verbosity tag
    if (-not $HideVerbosity) { $tag = [Verbosity]::GetTag($VerbosityLocal) }
    else { $tag = '' }


    #@ Add context unless explicitly hidden
    if (-not $HideContext) {
        $context = if ($callStack.Count -gt 1) {
            GetContext `
                -Context $Context -Scope $ContextScope `
                -Caller $callStack[1] `

        }
        else {
            GetContext -Context $Context -Scope $ContextScope
        }

        #@ Append duration if set
        if ($Duration) {
            $context += "  $Duration"
            # $context += " 󱇻 $Duration"
        }

        $tagHead = ">>="
        $tagTail = "=<<"
        $context = "$tagHead $context $tagTail"
    }
    else {
        $context = ''
    }

    #@ Separate the messages with the delimiter
    if ($NoNewLine) { $Delimiter = ' ' }
    $message = $Delimiter + ($Messages -join $Delimiter)
    if ($Delimiter -match '\r?\n') { $message += "`n" }

    #@ Output the message
    $fullMessage = "$timestamp$tag$context$message" -join ' '
    Write-Host $fullMessage -ForegroundColor ([Verbosity]::GetColor($VerbosityLocal))
}

function Global:RunCommand {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Quiet')]
        [switch]$Silent,

        [Parameter()]
        [Alias('d', 'v')]
        [switch]$Detailed,

        [Parameter()]
        [Alias('tag', 'level', 'lvl')]
        [string]$Verbosity,

        [Parameter()]
        [Alias('msg')]
        [string]$Message,

        [Parameter()]
        [Alias('ctx')]
        [string]$Context,

        [Parameter()]
        [Alias('scope')]
        [ValidateSet('Path', 'Name')]
        [string]$ContextScope,

        [Parameter()]
        [Alias('sep', 'delim', 'separator')]
        [string]$Delimiter = " ",

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    #@ Capture start time
    $startTime = Get-Date

    #@ Set the verbosity level
    if ($Silent) { $Verbosity = [Verbosity]::Quiet }
    elseif ($Detailed) { $Verbosity = [Verbosity]::Trace }

    $oldVerbosity = $Global:Verbosity
    $VerbosityLocal = [VerbosityInfo]::FromVerbosity($Verbosity)
    $Global:Verbosity = $VerbosityLocal

    #@ Set the context to the command name
    $Context = GetContext -Context $Command -Scope $ContextScope

    #@ Execute the command
    try {
        if ($Arguments) { & $Command @Arguments } else { & $Command }
        $Tag = [Verbosity]::Info
        if (-not $Message) { $Message = "Execution completed successfully" }
    }
    catch {
        $Tag = [Verbosity]::Error
        $Message = "Execution failed with the following message:`n($_.Exception.Message)"
    }

    #@ Calculate duration of the process
    $endTime = Get-Date
    $duration = $endTime - $startTime
    $milliseconds = [math]::Round($duration.TotalMilliseconds)
    $Runtime = "${milliseconds}ms"

    #@ Print debug information
    if ($DebugPreference -eq 'Continue') {
        Write-Debug "Command: $Command $($Arguments -join ', ')"
        Write-Debug "Verbosity: $($VerbosityLocal.Tag)[$($VerbosityLocal.Level)]"
        Write-Debug "Context: ${Context}"
        Write-Debug "StartTime: ${startTime}"
        Write-Debug "EndTime: $endTime"
        Write-Debug "Duration: $duration"
        Write-Debug "Milliseconds: $milliseconds"
        Write-Debug "Runtime: $Runtime"
        Write-Debug "ResultTag: $Tag"
        Write-Debug "ResultMessage: $Message"
    }

    #@ Print the result
    Pout `
        -Verbosity ${Tag} `
        -Context ${Context} `
        -Delimiter ${Delimiter} `
        -Duration ${Runtime} `
        -Message ${Message} `

    #@ Restore the verbosity level
    $Global:Verbosity = $oldVerbosity
}

#region DOTS

function LocateDOTS {
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
            'flake.nix'
        )
    )

    #@ Ensure arrays for input parameters
    $Parents = $Parents | ForEach-Object { NormalizePath $_ }
    $Targets = @($Targets)
    $Markers = @($Markers)
    Pout -Level [Verbosity]::Debug `
        "Parents: $($Parents -join ', ')" `
        "Targets: $($Targets -join ', ')" `
        "Markers: $($Markers -join ', ')" `

    foreach ($parent in $Parents) {
        if (-not (Test-Path -Path $parent -PathType Container)) { continue }

        foreach ($target in $Targets) {
            $potentialDOTS = & NormalizePath (Join-Path -Path $parent -ChildPath $target)
            if (-not (Test-Path -Path $potentialDOTS -PathType Container)) { continue }

            #@ Check if any of the marker files exist
            foreach ($marker in $Markers) {
                Pout -lvl "Trace" -msg "Searching for '$marker' in '$potentialDOTS'"

                $markerPath = & NormalizePath (Join-Path -Path $potentialDOTS -ChildPath $marker)
                if (Test-Path -Path $markerPath -PathType Leaf) {
                    #@ Set DOTS in all scopes
                    [Environment]::SetEnvironmentVariable('DOTS', $potentialDOTS, 'Process')
                    $Global:DOTS = $potentialDOTS
                    Set-Item -Path 'env:DOTS' -Value $potentialDOTS

                    Pout -lvl "Info" -msg "DOTS environment set to: $Global:DOTS"
                    return
                }
            }
        }
    }

    Pout -Level "Warn" -Message "No DOTS directory found"
}

function InitializeDOTS {
    [CmdletBinding()]
    param()

    try {
        #@ Check if DOTS is defined
        if (-not $env:DOTS) {
            Pout -Level Error -Message "DOTS environment variable not set"
            return $false
        }

        #@ Get profile path
        $profilePath = Join-Path $env:DOTS 'Configuration/powershell/profile.ps1'
        $dotsProfile = & NormalizePath $profilePath

        #@ Guard against recursive imports
        if ($dotsProfile -eq $PSCommandPath) {
            Pout -Level Debug -Message "Skipping recursive profile import"
            return $true
        }

        #@ Validate profile exists
        if (-not (Test-Path -Path $dotsProfile -PathType Leaf)) {
            Pout -Level Error -Message "PowerShell profile not found: $dotsProfile"
            return $false
        }

        #@ Set profile path in all scopes
        [Environment]::SetEnvironmentVariable('DOTS_PROFILE', $dotsProfile, 'Process')
        $Global:DOTS_PROFILE = $dotsProfile
        Set-Item -Path 'env:DOTS_PROFILE' -Value $dotsProfile

        Pout -Level Info -Message "Loading DOTS profile from: $dotsProfile"

        #@ Import the profile
        . $dotsProfile

        Pout -Level Debug -Message @(
            "Environment variables:"
            "DOTS: $($env:DOTS)"
            "DOTS_PROFILE: $($env:DOTS_PROFILE)"
        )
    }
    catch {
        Pout -Level Error -Message "Failed to import DOTS profile: $($_.Exception.Message)"
        throw $_.Exception
    }
}

#endregion

#region Main Execution

locateDOTS
# RunCommand LocateDOTS
# RunCommand InitializeDOTS

#endregion
