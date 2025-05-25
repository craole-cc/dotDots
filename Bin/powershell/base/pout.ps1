#region Main
function Write-Output {
    <#
    .SYNOPSIS
        Flexible, verbosity-aware output with context, timestamp, and color.
    .DESCRIPTION
        Outputs formatted messages based on verbosity, context, and user preferences.
    .PARAMETER Verbosity
        The verbosity level for this message (alias, name, or number).
    .PARAMETER MaxVerbosity
        The maximum verbosity to display (messages above this are suppressed).
    .PARAMETER Context
        Custom context string. If not provided, uses caller or invocation info.
    .PARAMETER ContextScope
        'Path' or 'Name'. Defaults based on verbosity if not provided.
    .PARAMETER ShowTimestamp
        If set, prepends a timestamp to the message.
    .PARAMETER NoNewLine
        If set, uses a space as the delimiter instead of a newline.
    .PARAMETER Duration
        Optional duration string to append to the context.
    .PARAMETER HideContext
        If set, omits context information.
    .PARAMETER HideVerbosity
        If set, omits the verbosity tag from output.
    .PARAMETER ForegroundColor
        Override the color for output.
    .PARAMETER Delimiter
        String to use between messages (default: newline and ===).
    .PARAMETER TagHead
        String to prepend to context (default: '>>=').
    .PARAMETER TagTail
        String to append to context (default: '=<<').
    .PARAMETER Messages
        The message(s) to output.
    #>
    [CmdletBinding()]
    param(
        [Alias('level', 'lvl','tag')]
        [Parameter()]
        [ValidateScript({ Test-Verbosity $_ })]
        $Verbosity = (Get-VerbosityDefault),

        [Alias('maxlevel', 'max', 'display')]
        [Parameter()]
        [ValidateScript({ Test-Verbosity $_ })]
        $MaxVerbosity = (Get-VerbosityDefault),

        [Alias('as', 'for', 'of', 'ctx')]
        [Parameter()]
        [string]$Context,

        [Alias('scope')]
        [Parameter()]
        [string]$ContextScope,

        [Alias('log')]
        [Parameter()]
        [switch]$ShowTimestamp,

        [Alias('noline')]
        [Parameter()]
        [switch]$NoNewLine,

        [Alias('time' , 'runtime')]
        [Parameter()]
        [string]$Duration,

        [Alias('noctx','NoContext')]
        [Parameter()]
        [switch]$HideContext,

        [Alias('noverb')]
        [Parameter()]
        [switch]$HideVerbosity,

        [Parameter()]
        [string]$ForegroundColor,

        [Alias('delim', 'separator', 'sep')]
        [Parameter()]
        [string]$Delimiter = "`n === ",

        [Parameter()]
        [string]$TagHead = '>>=',

        [Parameter()]
        [string]$TagTail = '=<<',

        [Alias('msg')]
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments)]
        [string[]]$Messages
    )

    #@ Normalize and compare verbosity levels
    $verbosityLevel = Set-Verbosity $Verbosity
    $maxLevel = Set-Verbosity $MaxVerbosity
    $verbosityNum = Get-VerbosityNumeric $verbosityLevel
    $maxNum = Get-VerbosityNumeric $maxLevel

    Write-Verbose "Importing module Write-Output"
    Write-Debug "Write-Output: Verbosity='$verbosityLevel' ($verbosityNum), Max='$maxLevel' ($maxNum)"

    if ($verbosityNum -gt $maxNum) {
        Write-Warning "Write-Output: Message suppressed (verbosity $verbosityNum > max $maxNum)"
        return
    }

    #@ Timestamp
    $timestamp = if ($ShowTimestamp) { Get-Date -Format '[yyyy-MM-dd HH:mm:ss] ' } else { '' }

    #@ Verbosity tag
    $tag = if (-not $HideVerbosity) { Get-VerbosityTag $verbosityLevel } else { '' }

    #@ Context
    $context = ''
    if (-not $HideContext) {
        $callStack = Get-PSCallStack
        $context = if ($callStack.Count -gt 1) {
            Get-Context `
                -Caller $callStack[1] `
                -Context $Context `
                -Scope $ContextScope `
                -Verbosity $verbosityLevel `
                -Duration $Duration `
                -TagHead $TagHead `
                -TagTail $TagTail
        }
        else {
            Get-Context `
                -Context $Context `
                -Scope $ContextScope `
                -Verbosity $verbosityLevel `
                -Duration $Duration `
                -TagHead $TagHead `
                -TagTail $TagTail
        }
    }

    #@ Message formatting
    if ($NoNewLine) { $Delimiter = ' ' }
    $message = $Delimiter + ($Messages -join $Delimiter)
    if ($Delimiter -match '\r?\n') { $message += "`n" }

    #@ Color selection
    $color = if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $ForegroundColor
    }
    else {
        Get-VerbosityColor $verbosityLevel
    }

    #@ Output
    $fullMessage = "$timestamp$tag$context$message" -join ' '
    Write-Host $fullMessage -ForegroundColor $color
}

#endregion
#region Test

function Global:Test-WriteOutput {
    <#
    .SYNOPSIS
        Runs diagnostic and simple output tests on the Write-Output function.
    .DESCRIPTION
        Outputs a variety of test cases using Write-Output, including basic and advanced scenarios.
    .EXAMPLE
        Test-WriteOutput
    #>
    [CmdletBinding()]
    param()

    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'

    Write-Host "`n=== Simple Examples ==="
    Write-Output -Verbosity 'Trace' -Messages 'This is a trace message'
    Write-Output -Verbosity 'Debug' -Messages 'This is a debug message'
    Write-Output -Verbosity 'Info'  -Messages 'This is an informational message'
    Write-Output -Verbosity 'Warn'  -Messages 'This is a warning message'
    Write-Output -Verbosity 'Error' -Messages 'This is an error message'

    Write-Host "`n=== Advanced/Diagnostic Examples ==="
    Write-Host "`nTest 1: Basic debug message"
    Write-Output -Verbosity 'Debug' -Messages 'Debug message'

    Write-Host "`nTest 2: Trace with context and timestamp"
    Write-Output -Verbosity 'Trace' -Context 'MyFunction' -ShowTimestamp -Messages 'Tracing...'

    Write-Host "`nTest 3: Error, hide verbosity tag"
    Write-Output -Verbosity 'Error' -HideVerbosity -Messages 'Error occurred!'

    Write-Host "`nTest 4: Custom tag head/tail and duration"
    Write-Output -Verbosity 'Information' -Context 'MyScript' -Duration '123ms' -TagHead '[[' -TagTail ']]' -Messages 'Info message with custom formatting'

    Write-Host "`nTest 5: Warning, no new line"
    Write-Output -Verbosity 'Warning' -NoNewLine 'Warning:' 'Check your config.'
}

#endregion
#region Export

#@ Export all public functions
Export-ModuleMember -Function @(
    'Write-Output',
    'Test-WriteOutput'
)

Set-Alias -Name pout -Value Write-Output

#endregion
