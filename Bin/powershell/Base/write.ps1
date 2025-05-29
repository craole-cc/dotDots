#TODO: think of everyway to improve this. Try to maintain my style and tooling

#region Main
function Write-Pretty {
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
        [Alias('level', 'lvl', 'tag')]
        [Parameter()]
        [ValidateScript({ Test-Verbosity $_ })]
        $Verbosity = (Get-VerbosityDefault),

        [Alias('maxlevel', 'max', 'display')]
        [Parameter()]
        [ValidateScript({ Test-Verbosity $_ })]
        $MaxVerbosity = (Get-VerbosityDefault),

        [Alias('ctx')]
        [Parameter()]
        [string]$Context,

        [Alias('as', 'for', 'of')]
        [Parameter()]
        [string]$ContextCustom,

        [Alias('scope')]
        [Parameter()]
        [string]$ContextScope,

        [Alias('log')]
        [Parameter()]
        [switch]$ShowTimestamp,

        [Alias('noline', 'oneline')]
        [Parameter()]
        [switch]$NoNewLine,

        [Alias('runtime')]
        [Parameter()]
        [string]$Duration,

        [Parameter()]
        [Alias('time', 'timeofinit', 'inittime', 'init', 'start', 'timein')]
        [datetime]$StartTime,

        [Parameter()]
        [Alias('timeofexit', 'exittime', 'exit', 'stop', 'timeout')]
        [datetime]$EndTime,

        [Alias('noctx', 'NoContext')]
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
        [string]$TagHead = '>>= ',

        [Parameter()]
        [string]$TagTail = ' =<<',

        [Alias('msg')]
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Messages
    )

    #@ Normalize and compare verbosity levels
    $verbosityLevel = Set-Verbosity $Verbosity
    $maxLevel = Set-Verbosity $MaxVerbosity
    $verbosityNum = Get-VerbosityNumeric $verbosityLevel
    $maxNum = Get-VerbosityNumeric $maxLevel

    Write-Verbose "Importing module Write-Pretty"
    # Write-Debug "Write-Pretty: Verbosity='$verbosityLevel' ($verbosityNum), Max='$maxLevel' ($maxNum)"

    if ($verbosityNum -gt $maxNum) {
        Write-Verbose "Write-Pretty: Message suppressed (verbosity $verbosityNum > max $maxNum)"
        return
    }

    #| Timestamp
    $timestamp = if ($ShowTimestamp) { Get-Timestamp -Format Default } else { '' }

    #| Verbosity Tag
    $tag = if (-not $HideVerbosity) { Get-VerbosityTag $verbosityLevel } else { '' }

    #| Duration
    if (-not $Duration -and $StartTime) {
        $durationMs = Get-DurationFromTimes -StartTime $StartTime -EndTime $(if ($EndTime) { $EndTime } else { Get-Date })

        if (-not $Messages) {
            $Messages = Get-DurationMessage -Duration $durationMs -Action "Initialization"
            $Duration = ''
            $NoNewLine = $true
        }
        else {
            $Duration = " $(Format-Duration -Duration $durationMs -Format Compact -IncludeIcon)"
        }
    }
    elseif ($Duration -and $Duration -match '^\d+(\.\d+)?$') {
        #@ If Duration is just a number, format it
        $Duration = " $(Format-Duration -Duration $Duration -Format Compact -IncludeIcon)"
    }
    elseif ($Duration) {
        #@ If Duration is already formatted, just add a space prefix
        $Duration = " $Duration"
    }

    #| Context
    $context =
    if ($HideContext) { '' } else {
        $callStack = Get-PSCallStack
        $ctx = if ($ContextCustom) { $ContextCustom }
        elseif ($callStack.Count -gt 1) {
            Get-Context `
                -Caller $callStack[1] `
                -Context $Context `
                -Scope $ContextScope `
                -Verbosity $verbosityLevel
        }
        else {
            Get-Context `
                -Context $Context `
                -Scope $ContextScope `
                -Verbosity $verbosityLevel
        }

        "${TagHead}${ctx}${Duration}${TagTail}"
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
    $fullMessage = "${timestamp}${tag}${context}${message}" -join ' '
    Write-Host $fullMessage -ForegroundColor $color
}

#endregion
#region Test

function Test-WritePretty {
    <#
    .SYNOPSIS
        Runs diagnostic and simple output tests on the Write-Pretty function.
    .DESCRIPTION
        Outputs a variety of test cases using Write-Pretty, including basic and advanced scenarios.
    .EXAMPLE
        Test-WritePretty
    #>
    [CmdletBinding()]
    param()

    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'

    Write-Host "`n=== Simple Examples ==="
    Write-Pretty -Verbosity 'Trace' -Messages 'This is a trace message'
    Write-Pretty -Verbosity 'Debug' -Messages 'This is a debug message'
    Write-Pretty -Verbosity 'Info'  -Messages 'This is an informational message'
    Write-Pretty -Verbosity 'Warn'  -Messages 'This is a warning message'
    Write-Pretty -Verbosity 'Error' -Messages 'This is an error message'

    Write-Host "`n=== Advanced/Diagnostic Examples ==="
    Write-Host "`nTest 1: Basic debug message"
    Write-Pretty -Verbosity 'Debug' -Messages 'Debug message'

    Write-Host "`nTest 2: Trace with context and timestamp"
    Write-Pretty -Verbosity 'Trace' -Context 'MyFunction' -ShowTimestamp -Messages 'Tracing...'

    Write-Host "`nTest 3: Error, hide verbosity tag"
    Write-Pretty -Verbosity 'Error' -HideVerbosity -Messages 'Error occurred!'

    Write-Host "`nTest 4: Custom tag head/tail and duration"
    Write-Pretty -Verbosity 'Information' -Context 'MyScript' -Duration '123' -TagHead '[[' -TagTail ']]' -Messages 'Info message with custom formatting'

    Write-Host "`nTest 5: Warning, no new line"
    Write-Pretty -Verbosity 'Warning' -NoNewLine 'Warning:' 'Check your config.'

    Write-Host "`nTest 6: Duration from start/end times"
    $startTime = (Get-Date).AddSeconds(-2)
    Write-Pretty -Verbosity 'Info' -StartTime $startTime -Messages 'Operation with measured duration'

    Write-Host "`nTest 7: Auto-generated duration message"
    $startTime = (Get-Date).AddMilliseconds(-1500)
    Write-Pretty -Verbosity 'Info' -StartTime $startTime
}

#endregion
#region Export

#@ Export all public functions
Export-ModuleMember -Function @(
    'Write-Pretty',
    'Test-WritePretty'
)

Set-Alias -Name pout -Value Write-Pretty
Export-ModuleMember -Alias 'pout'

#endregion
