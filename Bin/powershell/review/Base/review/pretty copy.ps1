#TODO: think of everyway to improve this. Try to maintain my style and tooling

#region Pretty
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
        String to use between messages (default: newline and >==>).
    .PARAMETER TagHead
        String to prepend to context (default: '>>=').
    .PARAMETER TagTail
        String to append to context (default: '=<<').
    .PARAMETER Messages
        The message(s) to output.
    #>
  [CmdletBinding()]
  param(
    [Alias('level', 'lvl')]
    [Parameter()]
    [ValidateScript({ Test-Verbosity $_ })]
    [String]$Tag,

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

    [Parameter()]
    [switch]$DebugEnv,

    [Alias('test', 'simulate', 'dry')]
    [Parameter()]
    [switch]$Force,

    [Alias('ask', 'interact')]
    [Parameter()]
    [switch]$Prompt,

    [Alias('noverb')]
    [Parameter()]
    [switch]$HideVerbosity,

    [Parameter()]
    [string]$ForegroundColor,

    [Alias('delim', 'separator', 'sep')]
    [Parameter()]
    [string]$Delimiter = "`n >==> ",

    [Parameter()]
    [string]$TagHead = '>>= ',

    [Parameter()]
    [string]$TagTail = ' =<<',

    [Alias('msg')]
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Messages
  )
  Write-Verbose 'Importing module Write-Pretty'

  #~@ Normalize and compare verbosity levels
  if ($Prompt) { $verbosityLevel = Get-VerbosityLevel 'Warn' }
  if ($Tag) { $verbosityLevel = Get-VerbosityLevel $Tag }
  $tagLevel = Get-VerbosityNumeric $verbosityLevel
  $maxLevel = if ($Force) { Get-VerbosityNumeric 'Trace' }
  elseif ($Prompt) { Get-VerbosityNumeric 'Warn' }
  else { Get-VerbosityNumeric $MaxVerbosity }

  if ($tagLevel -gt $maxLevel) {
    Write-Verbose "Write-Pretty: Message suppressed (verbosity $tagLevel > max $maxLevel)"
    return
  }

  #| Debug Environment Variables
  if ($DebugEnv) {
    if (-not $verbosityLevel) {
      if ($maxLevel -lt (Get-VerbosityNumeric 'Debug')) {
        Write-Verbose "Debugging environment variables is disabled for verbosity level: $(Get-VerbosityLevel $maxLevel)"
        return
      }
    }

    if (-not $Tag) {
      $verbosityLevel = Get-VerbosityLevel 'Debug'
    }
    $HideContext = $true
    $NoNewLine = $true
    if ($Messages.Length -gt 1) {
      $Messages = @("$($Messages[0]) => $($Messages[1..($Messages.Length - 1)] -join ' ')")
    }
  }

  if ($Prompt) {
    $verbosityLevel = Get-VerbosityLevel 'Warn'
    $HideContext = $true
    $NoNewLine = $true
  }

  #| Timestamp
  $timestamp = if ($ShowTimestamp) { Get-Timestamp -Format Default } else { '' }

  #| Verbosity Tag
  $tag = if (-not $HideVerbosity) { Get-VerbosityTag $verbosityLevel } else { '' }

  #| Duration
  if (-not $Duration -and $StartTime) {
    $durationMs = Get-DurationFromTimes -StartTime $StartTime -EndTime $(if ($EndTime) { $EndTime } else { Get-Date })

    if (-not $Messages) {
      $Messages = Get-DurationMessage -Duration $durationMs -Action 'Initialization'
      $Duration = ''
      $NoNewLine = $true
    }
    else {
      $Duration = " $(Format-Duration -Duration $durationMs -Format Compact -IncludeIcon)"
    }
  }
  elseif ($Duration -and $Duration -match '^\d+(\.\d+)?$') {
    #~@ If Duration is just a number, format it
    $Duration = " $(Format-Duration -Duration $Duration -Format Compact -IncludeIcon)"
  }
  elseif ($Duration) {
    #~@ If Duration is already formatted, just add a space prefix
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

  #~@ Message formatting
  if ($NoNewLine) { $Delimiter = ' ' }
  $message = $Delimiter + ($Messages -join $Delimiter)
  if ($Delimiter -match '\r?\n') { $message += "`n" }

  #~@ Color selection
  $color = if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
    $ForegroundColor
  }
  else {
    Get-VerbosityColor $verbosityLevel
  }

  #~@ Output
  $fullMessage = "${timestamp}${tag}${context}${message}" -join ' '
  Write-Host $fullMessage -ForegroundColor $color
}

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
  Write-Pretty -Verbosity 'Info' -Messages 'This is an informational message'
  Write-Pretty -Verbosity 'Warn' -Messages 'This is a warning message'
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

#region Pattern

<#
.SYNOPSIS
Repeats a pattern string optionally prefixed with a repeated pad string.

.DESCRIPTION
Write-Pattern outputs a string composed of repeated pattern characters optionally
preceded by a repeated padding string. The function supports flexible positional
and named parameters for specifying the pattern, repetition count, padding character,
and padding length.

It auto-detects argument types among up to four positional parameters, assigning integers
to repetition counts and strings to pattern characters based on their order and type.

.PARAMETER Args
Positional arguments (up to 4) combining pattern strings and repetition integers.
Integers are assigned first to repetition count, then padding count.
Strings are assigned first to pattern string, then padding string.

.PARAMETER Count
The number of times to repeat the pattern string. If not specified, defaults to 1.

.PARAMETER PadCount
The number of times to repeat the padding string before the pattern.
If a padding string is specified but PadCount is not, it defaults to 1.
Otherwise defaults to 0.

.PARAMETER PadPattern
The character(s) to use for padding before the pattern.
Defaults to a single space character.

.PARAMETER Pattern
The character(s) to repeat for output.
Defaults to newline (`n).

.EXAMPLES
Write-Pattern
# Prints a single newline.

.EXAMPLES
# Prints five newlines.
Write-Pattern 5

.EXAMPLES
Write-Pattern i 5
Returns 'iiiii'

.EXAMPLES
# Prints 'oiiiii' - one 'o' pad character pre-pended.
Write-Pattern i 5 o

.EXAMPLES
# Prints '   iiiii' - three space pad characters pre-pended.
Write-Pattern i 5 3

.EXAMPLES
# Prints 'oooiiiii' - three 'o' pad characters pre-pended.
Write-Pattern i 5 3 o

.EXAMPLES
# Prints 'oooiiiii' - three 'o' pad characters pre-pended (order of padding count/string swapped).
Write-Pattern i 5 o 3

.EXAMPLES
# Prints '-----**********'.
Write-Pattern -Pattern '*' -Count 10 -PadPattern '-' -PadCount 5

.NOTES
Supports named parameter aliases and flexible positional parameters.
Positional parameters beyond four throw an error.
Throws error if integers or strings exceed two occurrences each.

.LINK
https://github.com/craole-cc/dotDots/blob/main/Bin/powershell/Base/write.ps1

#>
function Write-Pattern {

  [CmdletBinding()]
  param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Args,

    [Alias('Length', 'Repetitions', 'Rep', 'Reps', 'Num')]
    [int]$Count = $null,

    [Alias('pc', 'PadLength', 'Pad', 'PadRepetitions', 'PadRep', 'PadReps', 'PadNum')]
    [int]$PadCount = $null,

    [Alias('pp', 'PadPat', 'PadStr', 'PadString')]
    [string]$PadPattern = $null,

    [Alias('p', 'pat', 'str', 'string')]
    [string]$Pattern = $null
  )

  begin {
    #~@ Set defaults if not provided or parsed from positional args
    if (-not $Pattern) {
      $Pattern = "`n"
    }
    if (-not $PadPattern) {
      $PadPattern = ' '
    }
    if (-not $Count) {
      $Count = 1
    }

    #~@ Separate positional args into integers and strings
    $intArgs = @()
    $strArgs = @()

    foreach ($a in $Args) {
      $success = $false
      [int]$num = 0
      $success = [int]::TryParse($a, [ref]$num)

      if ($success) {
        $intArgs += $num
      }
      else {
        $strArgs += $a
      }
    }

    #~@ Validate argument counts: maximum two integers and two strings allowed
    if ($intArgs.Count -gt 2 -or $strArgs.Count -gt 2) {
      throw 'Invalid argument count or types: maximum two integers and two strings allowed.'
    }

    #~@ Assign Count and PadCount from positional integers unless explicitly set by named params
    if (-not $PSBoundParameters.ContainsKey('Count') -and $intArgs.Count -ge 1) {
      $Count = $intArgs[0]
    }
    if (-not $PSBoundParameters.ContainsKey('PadCount') -and $intArgs.Count -ge 2) {
      $PadCount = $intArgs[1]
    }

    #~@ Assign Pattern and PadPattern from positional strings unless explicitly set by named params
    if (-not $PSBoundParameters.ContainsKey('Pattern') -and $strArgs.Count -ge 1) {
      $Pattern = $strArgs[0]
    }
    if (-not $PSBoundParameters.ContainsKey('PadPattern') -and $strArgs.Count -ge 2) {
      $PadPattern = $strArgs[1]
    }

    #~@ If a PadPattern is specified but PadCount is null or zero, default PadCount to 1
    if ((-not $PadCount -or $PadCount -eq 0) -and
      ( $PSBoundParameters.ContainsKey('PadPattern') -or ($strArgs.Count -ge 2) )
    ) {
      $PadCount = 1
    }

    #~@ Compose output string from repeated pad and pattern strings
    $padding = $PadPattern * $PadCount
    $patternString = $Pattern * $Count
    $output = $padding + $patternString

    #~@ Output the constructed string without extra newline
    Write-Host -NoNewline $output
  }
}

#endregion
#region Export

#~@ Export all public functions
Export-ModuleMember `
  -Function @(
  'Write-Pretty',
  'Test-WritePretty',
  'Write-Pattern'
) `
  -Alias @(
  "$(Set-Alias -Name pout -Value Write-Pattern)"
)

#endregion
