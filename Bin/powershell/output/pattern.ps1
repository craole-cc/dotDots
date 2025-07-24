#region Methods
function Global:Write-Pattern {
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

#region Aliaes
Set-Alias -Name pout -Value Write-Pattern -Scope Global
#endregion
