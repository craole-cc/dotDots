#Requires -Version 5.1

#region Settings
$Global:Verbosity = [Verbosity]::Trace
$VerbosePreference = 'Continue'
# $DebugPreference = 'Continue'

#endregion

#region Types

enum Verbosity {
    Off = 0
    Error = 1
    Warning = 2
    Information = 3
    Debug = 4
    Trace = 5
}

class VerbosityManager {
    static hidden [System.Collections.Generic.Dictionary[string, hashtable]] $LevelConfig
    static hidden [System.Collections.Generic.Dictionary[string, Verbosity]] $AliasMap
    static hidden [bool] $Initialized = $false

    static VerbosityManager() {
        [VerbosityManager]::Initialize()
    }

    static hidden [void] Initialize() {
        if ([VerbosityManager]::Initialized) { return }

        # Initialize dictionaries with case-insensitive comparers
        [VerbosityManager]::LevelConfig = [System.Collections.Generic.Dictionary[string, hashtable]]::new([System.StringComparer]::OrdinalIgnoreCase)
        [VerbosityManager]::AliasMap = [System.Collections.Generic.Dictionary[string, Verbosity]]::new([System.StringComparer]::OrdinalIgnoreCase)

        $config = @{
            Off         = @{
                Color   = 'Gray'
                Tag     = 'QUIET '
                Aliases = @('Q', 'Quiet', 'Silent', 'Off', 'None', 'Disabled', 'False', 'Grey', 'Gray', '0')
            }
            Error       = @{
                Color   = 'Red'
                Tag     = 'ERROR '
                Aliases = @('E', 'Error', 'Err', 'Fatal', 'Failure', 'Fail', 'Red', '1')
            }
            Warning     = @{
                Color   = 'Yellow'
                Tag     = 'WARN  '
                Aliases = @('W', 'Warn', 'Warning', 'Caution', 'Yellow', 'Amber', 'Orange', '2')
            }
            Information = @{
                Color   = 'Blue'
                Tag     = 'INFO  '
                Aliases = @('I', 'Information', 'Info', 'Inf', 'On', 'Enabled', 'True', 'Blue', '3')
            }
            Debug       = @{
                Color   = 'Green'
                Tag     = 'DEBUG '
                Aliases = @('D', 'Test', 'Dbg', 'Debug', 'Green', '4')
            }
            Trace       = @{
                Color   = 'Magenta'
                Tag     = 'TRACE '
                Aliases = @('T', 'Trace', 'Trc', 'Detailed', 'Verbose', 'Magenta', '5')
            }
        }

        # Build optimized lookup tables
        foreach ($level in $config.Keys) {
            $levelEnum = [Verbosity]$level
            [VerbosityManager]::LevelConfig[$level] = $config[$level]

            # Add primary name and all aliases to alias map
            [VerbosityManager]::AliasMap[$level] = $levelEnum
            foreach ($alias in $config[$level].Aliases) {
                [VerbosityManager]::AliasMap[$alias] = $levelEnum
            }
        }

        [VerbosityManager]::Initialized = $true
    }

    static [Verbosity] GetDefault() {
        return $Global:Verbosity ?? [Verbosity]::Information
    }

    static [string] GetColor([object] $level) {
        $verbosity = [VerbosityManager]::ToVerbosity($level)
        return [VerbosityManager]::LevelConfig[$verbosity.ToString()].Color
    }

    static [string] GetTag([object] $level) {
        $verbosity = [VerbosityManager]::ToVerbosity($level)
        return [VerbosityManager]::LevelConfig[$verbosity.ToString()].Tag
    }

    static [int] GetLevel([object] $level) {
        return [int][VerbosityManager]::ToVerbosity($level)
    }

    static [Verbosity] ToVerbosity([object] $value) {
        #@ Handle null - use global or default
        if ($null -eq $value -or $value -eq '') {
            Write-Verbose "Input is null/empty, using default"
            return [VerbosityManager]::GetDefault()
        }

        Write-Verbose "Converting value: $($value.GetType().Name) = '$value'"

        #@ Handle already correct type
        if ($value -is [Verbosity]) {
            Write-Verbose "  Already Verbosity enum: $value"
            return $value
        }

        #@ Handle numeric types (including [int], [byte], [long], etc.)
        if ($value -is [System.ValueType] -and ($value.GetType().IsPrimitive -and $value.GetType() -ne [bool] -and $value.GetType() -ne [char])) {
            $numValue = [Math]::Max(0, [Math]::Min(5, [int]$value))
            Write-Verbose "  Numeric value clamped: $value -> $numValue"
            return [Verbosity]$numValue
        }

        #@ Handle string-like inputs
        $stringValue = $value.ToString().Trim()
        if ([string]::IsNullOrWhiteSpace($stringValue)) {
            Write-Verbose "  Empty string, using default"
            return [VerbosityManager]::GetDefault()
        }

        #@ Try direct alias lookup (fastest path)
        if ([VerbosityManager]::AliasMap.ContainsKey($stringValue)) {
            $result = [VerbosityManager]::AliasMap[$stringValue]
            Write-Verbose "  Matched alias: '$stringValue' -> $result"
            return $result
        }

        #@ Try parsing as number first (to handle clamping)
        $numResult = 0
        if ([int]::TryParse($stringValue, [ref]$numResult)) {
            $clampedValue = [Math]::Max(0, [Math]::Min(5, $numResult))
            Write-Verbose "  Parsed as number: '$stringValue' -> $clampedValue"
            return [Verbosity]$clampedValue
        }

        #@ Try parsing as enum (for named values only)
        $enumResult = $null
        if ([System.Enum]::TryParse([Verbosity], $stringValue, $true, [ref]$enumResult)) {
            Write-Verbose "  Parsed as enum: '$stringValue' -> $enumResult"
            return $enumResult
        }

        #@ Fallback to default
        Write-Verbose "  No match found, using default"
        return [VerbosityManager]::GetDefault()
    }

    #@ Backward compatibility alias
    static [Verbosity] From([object] $value) {
        return [VerbosityManager]::ToVerbosity($value)
    }

    static [bool] IsValid([object] $value) {
        try {
            [VerbosityManager]::ToVerbosity($value) | Out-Null
            return $true
        }
        catch {
            return $false
        }
    }

    static [string[]] GetAllAliases() {
        return [VerbosityManager]::AliasMap.Keys | Sort-Object
    }

    static [string[]] GetAliasesFor([Verbosity] $level) {
        $config = [VerbosityManager]::LevelConfig[$level.ToString()]
        return @($level.ToString()) + $config.Aliases | Sort-Object
    }

    static [string] FormatMessage([object] $level, [string] $message) {
        $verbosity = [VerbosityManager]::ToVerbosity($level)
        $tag = [VerbosityManager]::GetTag($verbosity)
        return "$tag$message"
    }

    #@ PowerShell-friendly method for testing
    static [hashtable] GetDiagnostics([object] $value) {
        $inputType = if ($null -eq $value) { 'null' } else { $value.GetType().Name }
        $result = @{
            Input     = $value
            InputType = $inputType
            Result    = [VerbosityManager]::ToVerbosity($value)
            IsValid   = [VerbosityManager]::IsValid($value)
        }
        return $result
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

    #@ Use provided context if given
    return $Context
}

function Global:NormalizePath {
    [CmdletBinding()]
    param($path)

    $newPath = [System.IO.Path]::GetFullPath($path)
    $newPath = $newPath.Replace('\\', '/')
    $newPath = $newPath.Replace('\', '/')
    return $newPath
}

function Global:Pout {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('level', 'lvl')]
        [ValidateScript({ [VerbosityManager]::IsValid($_) })]
        $Tag,

        [Parameter()]
        [Alias('maxlevel', 'verbosity', 'display')]
        [ValidateScript({ [VerbosityManager]::IsValid($_) })]
        $Max,

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
    if ( [VerbosityManager]::GetLevel($Tag) -gt [VerbosityManager]::GetLevel($Max)) { return }
    Write-Host "Tag $([VerbosityManager]::GetTag($Tag))"
    Write-Host "Max $([VerbosityManager]::GetTag($Max))"
    # Write-Host "Verbosity $([VerbosityManager]::GetTag($Verbosity))"
    return
    [VerbosityManager]::GetTag($Tag)
    [VerbosityManager]::GetTag($Verbosity)
    if ([VerbosityManager]::GetLevel($Verbosity) -gt [VerbosityManager]::GetLevel($VerbosityMax)) { return }
    # Write-Host "Verbosity $([VerbosityManager]::GetTag($Verbosity))"
    #@ If Context scope is not provided, set defaults based on Verbosity enum
    if (-not $ContextScope) {
        $ContextScope = switch ($Verbosity) {
            [Verbosity]::Error { 'Path' }
            [Verbosity]::Debug { 'Path' }
            [Verbosity]::Trace { 'Path' }
            default { 'Name' }
        }
    }

    Write-Debug "Verbosity: $([VerbosityManager]::GetTag($Verbosity))[$Verbosity]"
    Write-Debug "Context: ${Context}"
    Write-Debug "ContextScope: $ContextScope"

    #@ Add timestamp if ShowTimestamp is set
    if ($ShowTimestamp)
    { $timestamp = Get-Date -Format '[yyyy-MM-dd HH:mm:ss] ' }
    else { $timestamp = '' }

    #@ Add verbosity tag
    if (-not $HideVerbosity) {
        $tag = [VerbosityManager]::GetTag($Verbosity)
    }
    else { $tag = '' }


    #@ Add context unless explicitly hidden
    if (-not $HideContext) {
        $callStack = Get-PSCallStack
        $context = if ($callStack.Count -gt 1) {
            GetContext `
                -Context $Context -Scope $ContextScope `
                -Caller $callStack[1]
        }
        else {
            GetContext -Context $Context -Scope $ContextScope
        }

        #@ Append duration if set
        if ($Duration) {
            $context += " ?? $Duration"
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
    Write-Host $fullMessage -ForegroundColor ([VerbosityManager]::GetColor($Verbosity))
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
    $VerbosityLocal = [VerbosityManager]::From($Verbosity)
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
        Write-Debug "Verbosity: $([VerbosityManager]::GetTag($VerbosityLocal))[$VerbosityLocal]"
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
        -Message ${Message}

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
        "Markers: $($Markers -join ', ')"

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

# LocateDOTS
# RunCommand LocateDOTS
# RunCommand InitializeDOTS
#

# Pout -Level [Verbosity]::Debug -Message "Test"
# Pout -Level "6" -Message "Test"
# Pout -Level 6 -Message "Test"
# Pout -Level -1 -Message "Test"
# Pout -Level Off -Message "Test"
# Pout -Level On -Message "Test"
# Pout -Level Fatal -Message "Test"


#TODO: Temporary
if (-not (Test-Path variable:DOTS)) {
    $Global:DOTS = "D:/Projects/GitHub/CC/.dots"
    [Environment]::SetEnvironmentVariable('DOTS', $Global:DOTS, 'Process')
    Set-Item -Path 'env:DOTS' -Value $Global:DOTS
    Write-Verbose "DOTS path set to: $Global:DOTS"
}
if (-not (Test-Path variable:DOTS_MOD)) {
    $Global:DOTS_MOD = Join-Path $DOTS "Modules"
    Write-Verbose "DOTS_MOD path set to: $Global:DOTS_MOD"
}
if (-not (Test-Path variable:DOTS_MOD_PS)) {
    $Global:DOTS_MOD_PS = Join-Path $DOTS_MOD "powershell"
    Write-Verbose "DOTS_MOD_PS path set to: $Global:DOTS_MOD_PS"
}


#endregion
