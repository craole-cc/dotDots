#region Methods
#TODO: Context Not working
function Global:Invoke-Process {
  <#
.SYNOPSIS
    Runs a command with arguments, reporting results with verbosity-aware output.
.DESCRIPTION
    Executes a command, measures duration, and outputs formatted results using Write-Pretty.
.PARAMETER Command
    The command to run (string).
.PARAMETER Arguments
    Arguments to pass to the command.
.PARAMETER Verbosity
    The verbosity level for reporting (alias, name, or number).
.PARAMETER Silent
    Suppress all output (sets verbosity to 'Off').
.PARAMETER Detailed
    Enable maximum verbosity (sets verbosity to 'Trace').
.PARAMETER Context
    Custom context string for output.
.PARAMETER ContextScope
    'Path' or 'Name' for context resolution.
.PARAMETER Delimiter
    String to use between messages.
.PARAMETER Message
    Custom message to display on success or error.
.EXAMPLE
    Invoke-Process 'Get-Process' -Arguments 'powershell'
#>
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

    [Alias('ctx')]
    [Parameter()]
    [string]$Context,

    [Parameter()]
    [ValidateSet('Path', 'Name')]
    [string]$Scope,

    [Parameter()]
    [Alias('sep', 'delim', 'separator')]
    [string]$Delimiter = ' ',

    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
  )

  #{ Capture the start time for calculating the duration
  $startTime = Get-Date

  #{ Determine effective verbosity
  if ($Silent) { $Verbosity = 'Off' }
  elseif ($Detailed) { $Verbosity = 'Trace' }
  $oldVerbosity = $Global:Verbosity
  $Global:Verbosity = Set-Verbosity $Verbosity

  # Write-Pretty -Context $Context -Scope $Scope POP -Tag 'Trace'
  Write-Host "Invoke-Process: Context:  $ctx"

  #{ Prepare context for output
  $ContextString = Get-Context -Context ($Context ?? $Command) -Scope $Scope
  Write-Debug "Invoke-Process: Context: $ContextString"

  try {
    if ($Arguments) {
      & $Command @Arguments
    }
    else {
      & $Command
    }
    $Tag = 'Information'
    if (-not $Message) { $Message = 'Execution completed successfully' }
  }
  catch {
    $Tag = 'Error'
    $Message = "Execution failed with the following message:`n$($_.Exception.Message)"
  }

  $Tag = Set-Verbosity $Tag
  $endTime = Get-Date
  $duration = $endTime - $startTime
  $milliseconds = [math]::Round($duration.TotalMilliseconds)
  $Runtime = "${milliseconds}ms"

  # if ($DebugPreference -eq 'Continue') {
  Write-Host "Invoke-Process: Command: $Command $($Arguments -join ', ')"
  Write-Host "Invoke-Process: Verbosity: $(Get-VerbosityTag $Tag)[$(Get-VerbosityNumeric $Tag)]"
  Write-Host "Invoke-Process: Context: ${ContextString}"
  Write-Host "Invoke-Process: StartTime: ${startTime}"
  Write-Host "Invoke-Process: EndTime: $endTime"
  Write-Host "Invoke-Process: Duration: $duration"
  Write-Host "Invoke-Process: Milliseconds: $milliseconds"
  Write-Host "Invoke-Process: Runtime: $Runtime"
  Write-Host "Invoke-Process: ResultTag: $Tag"
  Write-Host "Invoke-Process: ResultMessage: $Message"
  # }

  #{ Output result using Write-Pretty
  Write-Pretty `
    -Tag $Tag `
    -Delimiter $Delimiter `
    -Duration $Runtime `
    -Messages $Message `
    # -Context $ContextString `

  #{ Restore verbosity
  $Global:Verbosity = $oldVerbosity
}


function Test-Command_OLD {
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string[]]$Name
  )
  # $commands = Get-Command -Name $Name -ErrorAction SilentlyContinue
  $available = @()
  $unavailable = @()
  foreach ($item in $Name) {
    if (Get-Command -Name $item -ErrorAction SilentlyContinue) {
      $available += $item
    }
    else {
      $unavailable += $item
    }
  }

  $cmdInfo = foreach ($cmd in $(Get-Command -Name $available)) {
    if ($cmd.CommandType -eq 'Application') {
      " Name: $($cmd.Name)"
      " Type: $($cmd.CommandType)"
      " Path: $($cmd.Path)"
      '------------------------------------------------------'
    }
    else {
      " Name: $($cmd.Name)"
      " Type: $($cmd.CommandType)"
      '------------------------------------------------------'
    }
  }
  $details = @"
      Missing >=> $($unavailable -join ', ')
    Available >=> $($available -join ', ')
======================================================
$($cmdInfo -join "`n")
"@

  Write-Pretty -Force -Tag 'Info' -NoNewLine `
    "$Name`n$($details -join "`n")"
}

function Global:Test-Command {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string[]]$Name
  )

  begin {
    $AllNames = @()
    $pad = '  '          # Padding (indentation) for output lines
    $sep = ', '          # Separator for joining lists (e.g. available/unavailable)
    $div = 54      # Length of separator lines
  }

  process {
    $AllNames += $Name
  }

  end {
    if (-not $AllNames -or $AllNames.Count -eq 0) {
      Write-Warning 'No commands supplied.'
      return
    }

    $foundCommands = Get-Command -Name $AllNames -ErrorAction SilentlyContinue
    $foundNames = $foundCommands.Name | Sort-Object -Unique
    $AllNamesUnique = $AllNames | Sort-Object -Unique

    $available = $AllNamesUnique | Where-Object { $foundNames -contains $_ }
    $unavailable = $AllNamesUnique | Where-Object { $foundNames -notcontains $_ }

    $totalCount = $AllNamesUnique.Count
    $missingCount = $unavailable.Count
    $availableCount = $available.Count

    # Use $sep for consistent joining
    $missingLine = if ($missingCount -gt 0) {
      "$pad$missingCount of $totalCount missing: $($unavailable -join $sep)"
    }
    else {
      "${pad}0 of $totalCount missing"
    }

    $availableLine = if ($availableCount -gt 0) {
      "$pad$availableCount of $totalCount available: $($available -join $sep)"
    }
    else {
      "${pad}0 of $totalCount available"
    }

    $currentDateLine = "${pad}Current date: $((Get-Date).ToUniversalTime().AddHours(-5).ToString('dddd, MMMM d, yyyy, h:mm tt')) EST"

    $AllCmdDetails = @()
    $index = 0
    $commandsCount = $foundCommands.Count
    foreach ($cmd in $foundCommands) {
      $AllCmdDetails += "${pad}Name: $($cmd.Name)"
      $AllCmdDetails += "${pad}Type: $($cmd.CommandType)"
      if ($cmd.CommandType -eq 'Application') {
        $AllCmdDetails += "${pad}Path: $($cmd.Path)"
      }
      elseif ($cmd.CommandType -in 'Cmdlet', 'Function') {
        $AllCmdDetails += "${pad}Module: $($cmd.ModuleName)"
      }
      if ($index -lt $commandsCount - 1) {
        $AllCmdDetails += '-' * $div
      }
      $index++
    }

    $details = @"
$missingLine
$availableLine
$currentDateLine
'=' * $div
$($AllCmdDetails -join "`n")
"@

    Write-Host $details
  }
}


function Global:Get-CommandFirst {
  <#
        .SYNOPSIS
        Gets the first valid command object, optionally verifying executable path
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Alias('Executable', 'VerifyExecutable')]
    [switch]$Application
  )

  $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $command) { return $null }

  if ($Application) {
    if (-not $command.Source -or -not (Test-Path $command.Source -PathType Leaf)) {
      return $null
    }
  }

  return $command
}

function Global:Test-CommandAvailable {
  <#
        .SYNOPSIS
        Returns $true if command exists and has valid executable path
    #>
  [CmdletBinding()]
  param([string]$Name)

  return [bool](Get-CommandFirst -Name $Name -Application)
}

function Global:Test-CommandExists {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Global:IsCommand {
  param([string]$Name)
  return [bool](Test-CommandExists $Name)
}

# function Test-CommandExecutable {
#   <#
#     .SYNOPSIS
#     Returns $true if the given CommandInfo object has a valid, existing executable path.
#     .PARAMETER Command
#     The CommandInfo object to check (from Get-Command).
#     .OUTPUTS
#     [bool] True if the command is executable, otherwise false.
#     #>
#   param([Parameter(Mandatory)][object]$Command)

#   return $Command -and $Command.Source -and (Test-Path $Command.Source -PathType Leaf)
# }

#endregion
#region Test

function Global:Test-InvokeProcess {
  <#
.SYNOPSIS
    Runs diagnostic and sample tests for Invoke-Process.
.DESCRIPTION
    Demonstrates various Invoke-Process scenarios and output.
.EXAMPLE
    Test-InvokeProcess
#>
  [CmdletBinding()]
  param()

  $VerbosePreference = 'Continue'
  $DebugPreference = 'Continue'

  Write-Host "`n=== Invoke-Process Tests ==="

  Write-Host "`nTest 1: Invoke-Process with Get-Date"
  Invoke-Process 'Get-Date'

  Write-Host "`nTest 2: Invoke-Process with Write-Pretty"
  Invoke-Process 'Write-Pretty' -Arguments 'Hello, world!' -Verbosity 'Debug'

  Write-Host "`nTest 3: Invoke-Process with Detailed"
  Invoke-Process 'Get-Process' -Arguments 'powershell' -Detailed

  Write-Host "`nTest 4: Invoke-Process with error"
  Invoke-Process 'Fake-Command' -Message 'Custom error message'
}

#endregion
