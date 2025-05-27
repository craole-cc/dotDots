#region Main
#TODO: Context Not working
function Invoke-Process {
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
        [string]$Delimiter = " ",

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    #@ Capture the start time for calculating the duration
    $startTime = Get-Date

    #@ Determine effective verbosity
    if ($Silent) { $Verbosity = 'Off' }
    elseif ($Detailed) { $Verbosity = 'Trace' }
    $oldVerbosity = $Global:Verbosity
    $Global:Verbosity = Set-Verbosity $Verbosity

    # Write-Pretty -Context $Context -Scope $Scope POP -Tag 'Trace'
    Write-Host "Invoke-Process: Context:  $ctx"

    #@ Prepare context for output
    $ContextString = Get-Context -Context ($Context ?? $Command) -Scope $Scope
    Write-Debug "Invoke-Process: Context: $ContextString"

    try {
        if ($Arguments) {
            & $Command @Arguments
        } else {
            & $Command
        }
        $Tag = 'Information'
        if (-not $Message) { $Message = "Execution completed successfully" }
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

    #@ Output result using Write-Pretty
    Write-Pretty `
        -Verbosity $Tag `
        -Delimiter $Delimiter `
        -Duration $Runtime `
        -Messages $Message `
        # -Context $ContextString `

    #@ Restore verbosity
    $Global:Verbosity = $oldVerbosity
}

#endregion
#region Test

function Test-InvokeProcess {
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
#region Export

Export-ModuleMember -Function @(
    'Invoke-Process',
    'Test-InvokeProcess'
)

#endregion
