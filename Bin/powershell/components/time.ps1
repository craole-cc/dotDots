<#
.SYNOPSIS
    PowerShell Duration and Timestamp Utilities Module
.DESCRIPTION
    Provides duration parsing, formatting, timestamp generation, and display utilities with support for both
    compact (e.g., "2m 30s") and verbose (e.g., "2 minutes and 30 seconds") formats.
.AUTHOR
    Craig 'Craole' Cole
.COPYRIGHT
    (c) Craig 'Craole' Cole, 2025. All rights reserved.
.LICENSE
    MIT License
.NOTES
    This module is designed for modular dotfile and script management.
#>

#region Configuration

$script:DurationFormats = @{
    Compact = @{
        Minutes      = 'm'
        Seconds      = 's'
        Milliseconds = 'ms'
        Separator    = ' '
        Icon         = '󱇻'
    }
    Verbose = @{
        Minutes       = @{ Singular = 'minute'; Plural = 'minutes' }
        Seconds       = @{ Singular = 'second'; Plural = 'seconds' }
        Milliseconds  = @{ Singular = 'millisecond'; Plural = 'milliseconds' }
        Connector     = 'and'
        ListSeparator = ', '
    }
}

$script:TimestampFormats = @{
    Default  = '[yyyy-MM-dd HH:mm:ss]'
    Short    = '[HH:mm:ss]'
    ISO      = 'yyyy-MM-ddTHH:mm:ss.fffZ'
    Compact  = 'yyyyMMdd-HHmmss'
    Filename = 'yyyy-MM-dd_HH-mm-ss'
}

#endregion

#region Core Functions

function Global:ConvertTo-TimeSpan {
    <#
    .SYNOPSIS
        Converts various duration inputs to a TimeSpan object.
    .PARAMETER Duration
        The duration to convert (milliseconds as string/number, or TimeSpan object).
    .OUTPUTS
        [TimeSpan] The converted TimeSpan object.
    .EXAMPLE
        ConvertTo-TimeSpan "1500"     # 1.5 seconds
        ConvertTo-TimeSpan 2500       # 2.5 seconds
    #>
    [CmdletBinding()]
    [OutputType([TimeSpan])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        $Duration
    )

    process {
        if ($null -eq $Duration) {
            return [TimeSpan]::Zero
        }

        if ($Duration -is [TimeSpan]) {
            return $Duration
        }

        try {
            $milliseconds = [double]::Parse($Duration.ToString())
            return [TimeSpan]::FromMilliseconds($milliseconds)
        }
        catch {
            Write-Error "Invalid duration format: $Duration"
            return [TimeSpan]::Zero
        }
    }
}

function Global:Format-DurationCompact {
    <#
    .SYNOPSIS
        Formats a TimeSpan as a compact string (e.g., "2m 30s 500ms").
    .PARAMETER TimeSpan
        The TimeSpan to format.
    .PARAMETER IncludeIcon
        Whether to include the duration icon.
    .OUTPUTS
        [string] The compact duration string.
    .EXAMPLE
        Format-DurationCompact -TimeSpan ([TimeSpan]::FromSeconds(150.5))
        # Returns: "2m 30s 500ms"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [TimeSpan]$TimeSpan,

        [switch]$IncludeIcon
    )

    process {
        $parts = @()
        $config = $script:DurationFormats.Compact

        if ($TimeSpan.TotalMinutes -ge 1) {
            $minutes = [math]::Floor($TimeSpan.TotalMinutes)
            $parts += "$minutes$($config.Minutes)"
        }

        if ($TimeSpan.Seconds -gt 0) {
            $parts += "$($TimeSpan.Seconds)$($config.Seconds)"
        }

        # Always show milliseconds if no other units or if there are remaining milliseconds
        if ($TimeSpan.Milliseconds -gt 0 -or $parts.Count -eq 0) {
            $parts += "$($TimeSpan.Milliseconds)$($config.Milliseconds)"
        }

        $result = $parts -join $config.Separator

        if ($IncludeIcon) {
            $result = "$($config.Icon) $result"
        }

        return $result
    }
}

function Global:Format-DurationVerbose {
    <#
    .SYNOPSIS
        Formats a TimeSpan as a verbose, human-readable string.
    .PARAMETER TimeSpan
        The TimeSpan to format.
    .OUTPUTS
        [string] The verbose duration string with proper grammar.
    .EXAMPLE
        Format-DurationVerbose -TimeSpan ([TimeSpan]::FromSeconds(150.5))
        # Returns: "2 minutes and 30 seconds"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [TimeSpan]$TimeSpan
    )

    process {
        $parts = @()
        $config = $script:DurationFormats.Verbose

        if ($TimeSpan.TotalMinutes -ge 1) {
            $minutes = [math]::Floor($TimeSpan.TotalMinutes)
            $unit = if ($minutes -eq 1) { $config.Minutes.Singular } else { $config.Minutes.Plural }
            $parts += "$minutes $unit"

            $remainingSeconds = [math]::Floor($TimeSpan.TotalSeconds % 60)
            if ($remainingSeconds -gt 0) {
                $unit = if ($remainingSeconds -eq 1) { $config.Seconds.Singular } else { $config.Seconds.Plural }
                $parts += "$remainingSeconds $unit"
            }
        }
        elseif ($TimeSpan.TotalSeconds -ge 1) {
            $seconds = [math]::Floor($TimeSpan.TotalSeconds)
            $unit = if ($seconds -eq 1) { $config.Seconds.Singular } else { $config.Seconds.Plural }
            $parts += "$seconds $unit"

            $remainingMs = [math]::Floor($TimeSpan.TotalMilliseconds % 1000)
            if ($remainingMs -gt 0) {
                $unit = if ($remainingMs -eq 1) { $config.Milliseconds.Singular } else { $config.Milliseconds.Plural }
                $parts += "$remainingMs $unit"
            }
        }
        else {
            $milliseconds = [math]::Floor($TimeSpan.TotalMilliseconds)
            $unit = if ($milliseconds -eq 1) { $config.Milliseconds.Singular } else { $config.Milliseconds.Plural }
            $parts += "$milliseconds $unit"
        }

        # Join parts with proper grammar
        return Join-DurationParts -Parts $parts
    }
}

function Global:Join-DurationParts {
    <#
    .SYNOPSIS
        Joins duration parts with proper English grammar.
    .PARAMETER Parts
        Array of duration parts to join.
    .OUTPUTS
        [string] Grammatically correct joined string.
    .EXAMPLE
        Join-DurationParts @("2 minutes", "30 seconds")
        # Returns: "2 minutes and 30 seconds"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$Parts
    )

    $config = $script:DurationFormats.Verbose

    switch ($Parts.Count) {
        0 { return '' }
        1 { return $Parts[0] }
        2 { return "$($Parts[0]) $($config.Connector) $($Parts[1])" }
        default {
            $lastIndex = $Parts.Count - 1
            $firstParts = $Parts[0..($lastIndex - 1)] -join $config.ListSeparator
            return "$firstParts$($config.ListSeparator)$($config.Connector) $($Parts[$lastIndex])"
        }
    }
}

function Global:Get-DurationFromTimes {
    <#
    .SYNOPSIS
        Calculates duration between start and end times.
    .PARAMETER StartTime
        The start time as a DateTime object.
    .PARAMETER EndTime
        The end time as a DateTime object. If not provided, uses current time.
    .OUTPUTS
        [double] Duration in milliseconds.
    .EXAMPLE
        Get-DurationFromTimes -StartTime (Get-Date).AddSeconds(-30)
        # Returns duration from 30 seconds ago to now
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter()]
        [datetime]$EndTime = (Get-Date)
    )

    $timespan = New-TimeSpan -Start $StartTime -End $EndTime
    return $timespan.TotalMilliseconds
}

#endregion

#region Timestamp Functions

function Global:Get-Timestamp {
    <#
    .SYNOPSIS
        Generates formatted timestamps for various use cases.
    .PARAMETER Format
        The timestamp format to use: Default, Short, ISO, Compact, Filename, or custom format string.
    .PARAMETER DateTime
        The DateTime to format. If not provided, uses current time.
    .PARAMETER IncludeBrackets
        Whether to include brackets around the timestamp (for Default and Short formats).
    .OUTPUTS
        [string] The formatted timestamp.
    .EXAMPLE
        Get-Timestamp
        # Returns: "[2025-05-27 14:30:45]"

        Get-Timestamp -Format Short
        # Returns: "[14:30:45]"

        Get-Timestamp -Format ISO
        # Returns: "2025-05-27T14:30:45.123Z"

        Get-Timestamp -Format "yyyy-MM-dd"
        # Returns: "2025-05-27"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$Format = 'Default',

        [Parameter()]
        [datetime]$DateTime = (Get-Date),

        [Parameter()]
        [switch]$IncludeBrackets
    )

    # Determine the format string to use
    $formatString = if ($script:TimestampFormats.ContainsKey($Format)) {
        $script:TimestampFormats[$Format]
    }
    else {
        # Treat as custom format string
        $Format
    }

    # Handle bracket inclusion for Default and Short formats
    if ($IncludeBrackets -and $Format -in @('Default', 'Short')) {
        $formatString = "[$($formatString.Trim('[]'))]"
    }
    elseif (-not $IncludeBrackets -and $Format -in @('Default', 'Short')) {
        $formatString = $formatString.Trim('[]')
    }

    try {
        return $DateTime.ToString($formatString)
    }
    catch {
        Write-Error "Invalid timestamp format: $formatString"
        return $DateTime.ToString()
    }
}

Set-Alias -Name 'timestamp' -Value 'Get-Timestamp' -Scope Global

#endregion

#region High-Level Functions

function Global:Format-Duration {
    <#
    .SYNOPSIS
        Formats a duration in the specified format (compact or verbose).
    .PARAMETER Duration
        The duration to format (milliseconds, TimeSpan, etc.).
    .PARAMETER Format
        The format to use: 'Compact' or 'Verbose'.
    .PARAMETER IncludeIcon
        Whether to include an icon (compact format only).
    .OUTPUTS
        [string] The formatted duration string.
    .EXAMPLE
        Format-Duration -Duration 90500 -Format Compact
        # Returns: "1m 30s 500ms"

        Format-Duration -Duration 90500 -Format Verbose
        # Returns: "1 minute and 30 seconds"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Duration,

        [Parameter()]
        [ValidateSet('Compact', 'Verbose')]
        [string]$Format = 'Compact',

        [switch]$IncludeIcon
    )

    process {
        $timeSpan = ConvertTo-TimeSpan -Duration $Duration

        switch ($Format) {
            'Compact' {
                Format-DurationCompact -TimeSpan $timeSpan -IncludeIcon:$IncludeIcon
            }
            'Verbose' {
                Format-DurationVerbose -TimeSpan $timeSpan
            }
        }
    }
}

function Global:Get-DurationMessage {
    <#
    .SYNOPSIS
        Creates completion messages with duration information.
    .PARAMETER Duration
        The duration to include in the message.
    .PARAMETER Action
        The action that was completed (default: "Operation").
    .PARAMETER Format
        The duration format to use.
    .OUTPUTS
        [string] A complete message with duration.
    .EXAMPLE
        Get-DurationMessage -Duration 1500 -Action "Initialization"
        # Returns: "Initialization completed in 1 second and 500 milliseconds."
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        $Duration,

        [Parameter()]
        [string]$Action = "Operation",

        [Parameter()]
        [ValidateSet('Compact', 'Verbose')]
        [string]$Format = 'Verbose'
    )

    $formattedDuration = Format-Duration -Duration $Duration -Format $Format
    return "$Action completed in $formattedDuration."
}

function Global:Measure-ScriptBlock {
    <#
    .SYNOPSIS
        Measures the execution time of a script block and optionally formats the result.
    .PARAMETER ScriptBlock
        The script block to measure.
    .PARAMETER Format
        The format for the duration output.
    .PARAMETER Action
        Optional action name for the completion message.
    .PARAMETER ReturnMessage
        If set, returns a formatted completion message instead of just the duration.
    .OUTPUTS
        [string] Either the formatted duration or completion message.
    .EXAMPLE
        Measure-ScriptBlock { Start-Sleep -Seconds 2 } -Format Compact
        # Returns: "2s 1ms"

        Measure-ScriptBlock { Get-Process } -Action "Process enumeration" -ReturnMessage
        # Returns: "Process enumeration completed in 245 milliseconds."
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [ValidateSet('Compact', 'Verbose')]
        [string]$Format = 'Compact',

        [Parameter()]
        [string]$Action,

        [Parameter()]
        [switch]$ReturnMessage
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $ScriptBlock
    }
    finally {
        $stopwatch.Stop()
    }

    $duration = $stopwatch.ElapsedMilliseconds

    if ($ReturnMessage -and $Action) {
        return Get-DurationMessage -Duration $duration -Action $Action -Format $Format
    }
    else {
        return Format-Duration -Duration $duration -Format $Format
    }
}

#endregion
#region Testing

function Global:Test-Duration {
    <#
    .SYNOPSIS
        Tests the duration formatting functions with various inputs.
    .EXAMPLE
        Test-Duration
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n=== Duration Module Tests ==="

    $testCases = @(
        @{ Duration = 500; Description = "500ms" }
        @{ Duration = 1500; Description = "1.5 seconds" }
        @{ Duration = 65000; Description = "1 minute 5 seconds" }
        @{ Duration = 125500; Description = "2 minutes 5.5 seconds" }
        @{ Duration = 3661500; Description = "1 hour 1 minute 1.5 seconds" }
    )

    foreach ($test in $testCases) {
        Write-Host "`nTesting: $($test.Description) ($($test.Duration)ms)"
        Write-Host "  Compact: $(Format-Duration -Duration $test.Duration -Format Compact)"
        Write-Host "  Compact with icon: $(Format-Duration -Duration $test.Duration -Format Compact -IncludeIcon)"
        Write-Host "  Verbose: $(Format-Duration -Duration $test.Duration -Format Verbose)"
        Write-Host "  Message: $(Get-DurationMessage -Duration $test.Duration -Action 'Test operation')"
    }

    Write-Host "`n=== Edge Cases ==="
    Write-Host "Zero duration: $(Format-Duration -Duration 0 -Format Verbose)"
    Write-Host "Null duration: $(Format-Duration -Duration $null -Format Compact)"

    Write-Host "`n=== TimeSpan Input ==="
    $timeSpan = [TimeSpan]::FromSeconds(75.25)
    Write-Host "TimeSpan input: $(Format-Duration -Duration $timeSpan -Format Verbose)"

    Write-Host "`n=== Timestamp Tests ==="
    Write-Host "Default: $(Get-Timestamp)"
    Write-Host "Short: $(Get-Timestamp -Format Short)"
    Write-Host "ISO: $(Get-Timestamp -Format ISO)"
    Write-Host "Compact: $(Get-Timestamp -Format Compact)"
    Write-Host "Filename: $(Get-Timestamp -Format Filename)"
    Write-Host "Custom: $(Get-Timestamp -Format 'yyyy-MM-dd')"
    Write-Host "No brackets: $(Get-Timestamp -Format Default -IncludeBrackets:$false)"

    Write-Host "`n=== Measure-ScriptBlock Test ==="
    $duration = Measure-ScriptBlock { Start-Sleep -Milliseconds 100 } -Format Compact
    Write-Host "Sleep test duration: $duration"

    $message = Measure-ScriptBlock { Get-Date } -Action "Date retrieval" -ReturnMessage
    Write-Host $message
}

#endregion
