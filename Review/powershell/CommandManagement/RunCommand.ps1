function Global:RunCommand {
    [CmdletBinding()]
    param(
        [Alias('Quiet')]
        [Parameter()]
        [switch]$Silent,

        [Alias('d', 'v')]
        [Parameter()]
        [switch]$Detailed,

        [Alias('tag', 'level', 'lvl')]
        [Parameter()]
        [string]$Verbosity,

        [Alias('msg')]
        [Parameter()]
        [string]$Message,

        [Alias('ctx')]
        [Parameter()]
        [string]$Context,

        [Alias('scope')]
        [Parameter()]
        [ValidateSet('Path', 'Name')]
        [string]$ContextScope,

        [Alias('sep', 'delim', 'separator')]
        [Parameter()]
        [string]$Delimiter = " ",

        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $startTime = Get-Date

    if ($Silent) { $Verbosity = 'Off' }
    elseif ($Detailed) { $Verbosity = 'Trace' }

    $oldVerbosity = $Global:Verbosity
    $VerbosityLocal = Get-VerbosityLevel $Verbosity
    $Global:Verbosity = $VerbosityLocal

    $Context = GetContext -Context $Command -Scope $ContextScope

    try {
        if ($Arguments) { & $Command @Arguments } else { & $Command }
        $Tag = 'Information'
        if (-not $Message) { $Message = "Execution completed successfully" }
    }
    catch {
        $Tag = 'Error'
        $Message = "Execution failed with the following message:`n($_.Exception.Message)"
    }

    $endTime = Get-Date
    $duration = $endTime - $startTime
    $milliseconds = [math]::Round($duration.TotalMilliseconds)
    $Runtime = "${milliseconds}ms"

    if ($DebugPreference -eq 'Continue') {
        Write-Debug "Command: $Command $($Arguments -join ', ')"
        Write-Debug "Verbosity: $(Get-VerbosityTag $VerbosityLocal)[$VerbosityLocal]"
        Write-Debug "Context: ${Context}"
        Write-Debug "StartTime: ${startTime}"
        Write-Debug "EndTime: $endTime"
        Write-Debug "Duration: $duration"
        Write-Debug "Milliseconds: $milliseconds"
        Write-Debug "Runtime: $Runtime"
        Write-Debug "ResultTag: $Tag"
        Write-Debug "ResultMessage: $Message"
    }

    Pout `
        -Verbosity ${Tag} `
        -Context ${Context} `
        -Delimiter ${Delimiter} `
        -Duration ${Runtime} `
        -Messages ${Message}

    $Global:Verbosity = $oldVerbosity
}
