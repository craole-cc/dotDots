<#
.SYNOPSIS
    PowerShell Verbosity Utilities Module
.DESCRIPTION
    Provides a robust, extensible verbosity system for scripts and modules, supporting aliases, numeric levels, color, and tags.
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

$script:VerbosityDefault = 'Information'
$script:VerbosityConfig = @{
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
        Aliases = @('D', 'Test', 'Dbg', 'Debug', 'Green', 'Success', '4')
    }
    Trace       = @{
        Color   = 'Magenta'
        Tag     = 'TRACE '
        Aliases = @('T', 'Trace', 'Trc', 'Detailed', 'Verbose', 'Magenta', '5')
    }
}

#{ Build case-insensitive alias map
$script:VerbosityAliasMap = @{}
foreach ($level in $script:VerbosityConfig.Keys) {
    $script:VerbosityAliasMap[$level.ToLower()] = $level
    foreach ($alias in $script:VerbosityConfig[$level].Aliases) {
        $script:VerbosityAliasMap[$alias.ToLower()] = $level
    }
}

#{ Level to numeric mapping for performance
$script:VerbosityNumericMap = @{
    'Off'         = 0
    'Error'       = 1
    'Warning'     = 2
    'Information' = 3
    'Debug'       = 4
    'Trace'       = 5
}

#{ Numeric to level mapping
$script:NumericToLevelMap = @('Off', 'Error', 'Warning', 'Information', 'Debug', 'Trace')

#endregion
#region Methods

function Set-Verbosity {
    <#
    .SYNOPSIS
        Normalizes a verbosity value to the canonical level name.
    .PARAMETER Value
        The verbosity value to normalize.
    .OUTPUTS
        [string] The canonical verbosity level name.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Value
    )

    #{ Handle null or empty
    if ($null -eq $Value -or $Value -eq '') {
        Write-Verbose "Input is null/empty, using default"
        return Get-VerbosityDefault
    }

    Write-Verbose "Converting value: $($Value.GetType().Name) = '$Value'"

    #{ Handle numeric types (including [int], [long], [double], etc.)
    if ($Value -is [System.ValueType] -and $Value.GetType().IsPrimitive -and
        $Value.GetType() -ne [bool] -and $Value.GetType() -ne [char]) {

        try {
            $numValue = [Math]::Max(0, [Math]::Min(5, [int]$Value))
            Write-Verbose "  Numeric value clamped: $Value -> $numValue"
            return $script:NumericToLevelMap[$numValue]
        }
        catch {
            Write-Verbose "  Failed to convert numeric value, using default"
            return Get-VerbosityDefault
        }
    }

    #{ Handle string-like inputs
    $stringValue = $Value.ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($stringValue)) {
        Write-Verbose "  Empty string, using default"
        return Get-VerbosityDefault
    }

    #{ Try direct alias lookup (case-insensitive)
    $lowerStringValue = $stringValue.ToLower()
    if ($script:VerbosityAliasMap.ContainsKey($lowerStringValue)) {
        $result = $script:VerbosityAliasMap[$lowerStringValue]
        Write-Verbose "  Matched alias: '$stringValue' -> $result"
        return $result
    }

    #{ Try parsing as number (to handle string numbers with clamping)
    $numResult = 0
    if ([int]::TryParse($stringValue, [ref]$numResult)) {
        $clampedValue = [Math]::Max(0, [Math]::Min(5, $numResult))
        Write-Verbose "  Parsed as number: '$stringValue' -> $clampedValue"
        return $script:NumericToLevelMap[$clampedValue]
    }

    #{ Fallback to default
    Write-Verbose "  No match found for '$stringValue', using default"
    return Get-VerbosityDefault
}

function Get-Verbosity {
    <#
    .SYNOPSIS
    Returns a detailed breakdown of a verbosity value, including canonical level, numeric value, tag, and validation.
    .PARAMETER Value
    The verbosity value to analyze (can be a string, alias, or number).
    .EXAMPLE
    Get-Verbosity 'green'
    Get-Verbosity 4
    Get-Verbosity 'Debug'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Value
    )

    $inputType = if ($null -eq $Value) { 'null' } else { $Value.GetType().Name }

    try {
        $level = Get-VerbosityLevel -Value $Value
        $numeric = Get-VerbosityNumeric -Level $level
        $tag = Get-VerbosityTag -Level $level
        $color = Get-VerbosityColor -Level $level
        $isValid = $true
    }
    catch {
        $level = $null
        $numeric = $null
        $tag = $null
        $color = $null
        $isValid = $false
    }

    [PSCustomObject]@{
        Input     = $Value
        InputType = $inputType
        Canonical = $level
        Numeric   = $numeric
        Tag       = $tag
        Color     = $color
        IsValid   = $isValid
    }
}

function Get-VerbosityDefault {
    <#
    .SYNOPSIS
        Returns the canonical default verbosity level for the current session.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    #{ If $Global:Verbosity is set, use it; otherwise, use the configured default.
    return Get-VerbosityLevel -Value ($Global:Verbosity ?? $script:VerbosityDefault)
}

function Get-VerbosityLevel {
    <#
    .SYNOPSIS
    Resolves a verbosity value (alias, number, or name) to the canonical level name.
    .PARAMETER Value
    The verbosity value to resolve.
    .EXAMPLE
    Get-VerbosityLevel 'green'   # returns 'Debug'
    Get-VerbosityLevel 5         # returns 'Trace'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Value
    )

    return Set-Verbosity -Value $Value
}

function Get-VerbosityNumeric {
    <#
    .SYNOPSIS
    Returns the numeric value (0-5) for a verbosity level.
    .PARAMETER Level
    The verbosity level to convert to numeric.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Level
    )

    $canonicalLevel = Get-VerbosityLevel -Value $Level
    return $script:VerbosityNumericMap[$canonicalLevel]
}

function Get-VerbosityColor {
    <#
    .SYNOPSIS
    Returns the color associated with a verbosity level.
    .PARAMETER Level
    The verbosity level to get the color for.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Level
    )

    $canonicalLevel = Get-VerbosityLevel -Value $Level
    return $script:VerbosityConfig[$canonicalLevel].Color
}

function Get-VerbosityTag {
    <#
    .SYNOPSIS
    Returns the tag/label for a verbosity level.
    .PARAMETER Level
    The verbosity level to get the tag for.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Level
    )

    $canonicalLevel = Get-VerbosityLevel -Value $Level
    return $script:VerbosityConfig[$canonicalLevel].Tag
}

#endregion
#region Utilities

function Test-Verbosity {
    <#
    .SYNOPSIS
    Returns $true if the value can be resolved to a valid verbosity level.
    .PARAMETER Value
    The value to test for verbosity validity.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Position = 0)]
        [AllowNull()]
        [object]$Value
    )

    try {
        $null = Get-VerbosityLevel -Value $Value
        return $true
    }
    catch {
        return $false
    }
}

function Get-VerbosityAllAliases {
    <#
    .SYNOPSIS
    Returns all valid verbosity aliases and level names.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return $script:VerbosityAliasMap.Keys | Sort-Object
}

function Get-VerbosityAliasesFor {
    <#
    .SYNOPSIS
    Returns all aliases for a given verbosity level.
    .PARAMETER Level
    The verbosity level to get aliases for.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [object]$Level
    )

    $canonicalLevel = Get-VerbosityLevel -Value $Level
    return @($canonicalLevel) + $script:VerbosityConfig[$canonicalLevel].Aliases | Sort-Object
}

function Format-VerbosityMessage {
    <#
    .SYNOPSIS
    Formats a message with the verbosity tag.
    .PARAMETER Level
    The verbosity level for the message.
    .PARAMETER Message
    The message to format.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [object]$Level,

        [Parameter(Position = 1, Mandatory)]
        [string]$Message
    )

    $canonicalLevel = Get-VerbosityLevel -Value $Level
    $tag = $script:VerbosityConfig[$canonicalLevel].Tag
    return "$tag$Message"
}

function Write-VerbosityMessage {
    <#
    .SYNOPSIS
    Writes a colored message with verbosity tag to the console.
    .PARAMETER Level
    The verbosity level for the message.
    .PARAMETER Message
    The message to write.
    .PARAMETER NoNewline
    Suppress the trailing newline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [object]$Level,

        [Parameter(Position = 1, Mandatory)]
        [string]$Message,

        [switch]$NoNewline
    )

    $canonicalLevel = Get-VerbosityLevel -Value $Level
    $color = $script:VerbosityConfig[$canonicalLevel].Color
    $formattedMessage = Format-VerbosityMessage -Level $canonicalLevel -Message $Message

    $writeHostParams = @{
        Object          = $formattedMessage
        ForegroundColor = $color
    }

    if ($NoNewline) {
        $writeHostParams.NoNewline = $true
    }

    Write-Host @writeHostParams
}

function Compare-VerbosityLevel {
    <#
    .SYNOPSIS
    Compares two verbosity levels numerically.
    .PARAMETER Level1
    The first verbosity level to compare.
    .PARAMETER Level2
    The second verbosity level to compare.
    .OUTPUTS
    [int] -1 if Level1 < Level2, 0 if equal, 1 if Level1 > Level2
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [object]$Level1,

        [Parameter(Position = 1, Mandatory)]
        [object]$Level2
    )

    $numeric1 = Get-VerbosityNumeric -Level $Level1
    $numeric2 = Get-VerbosityNumeric -Level $Level2

    return [Math]::Sign($numeric1 - $numeric2)
}

function Test-VerbosityLevelMeetsThreshold {
    <#
    .SYNOPSIS
    Tests if a verbosity level meets or exceeds a threshold.
    .PARAMETER Level
    The verbosity level to test.
    .PARAMETER Threshold
    The minimum threshold level.
    .OUTPUTS
    [bool] $true if Level >= Threshold numerically
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Position = 0, Mandatory)]
        [object]$Level,

        [Parameter(Position = 1, Mandatory)]
        [object]$Threshold
    )

    $levelNumeric = Get-VerbosityNumeric -Level $Level
    $thresholdNumeric = Get-VerbosityNumeric -Level $Threshold

    return $levelNumeric -ge $thresholdNumeric
}

#endregion
#region Export

#{ Export all public functions
Export-ModuleMember -Function @(
    'Get-VerbosityDefault',
    'Get-VerbosityLevel',
    'Get-VerbosityNumeric',
    'Get-VerbosityColor',
    'Get-VerbosityTag',
    'Get-Verbosity',
    'Set-Verbosity',
    'Test-Verbosity',
    'Get-VerbosityAllAliases',
    'Get-VerbosityAliasesFor',
    'Format-VerbosityMessage',
    'Write-VerbosityMessage',
    'Compare-VerbosityLevel',
    'Test-VerbosityLevelMeetsThreshold'
)

#endregion
