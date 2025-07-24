#region Methods

function Global:Get-Context {
    <#
.SYNOPSIS
    Resolves and formats a context string for logging/output, with scope and verbosity awareness.
.DESCRIPTION
    Determines the context to display (e.g., function name, script path, or custom string),
    optionally wraps it with tag head/tail, and appends duration if provided.
.PARAMETER Context
    A custom context string to display. If not provided, uses caller or invocation info.
.PARAMETER Scope
    'Path' to use the script path, 'Name' to use the function name. Defaults by verbosity.
.PARAMETER Verbosity
    The verbosity level to use for default scope selection.
.PARAMETER Duration
    Optional: Duration string to append.
.PARAMETER Caller
    Optional: The caller object from the call stack.
.EXAMPLE
    Get-Context -Verbosity 'Error' -Caller $callStack[1] -Duration '15ms'
.NOTES
    (c) Craig 'Craole' Cole, 2025. All rights reserved.
#>
    [CmdletBinding()]
    param(
        [string]$Context,
        [string]$Scope,
        [string]$Verbosity = (Get-VerbosityDefault),
        $Caller
    )

    Write-Verbose "Get-Context: Called with Context='$Context', Scope='$Scope', Verbosity='$Verbosity'"
    Write-Debug   "Get-Context: Caller: $($Caller | Out-String)"

    if (-not $Scope) {
        $resolvedVerbosity = Set-Verbosity $Verbosity
        Write-Verbose "Get-Context: Scope not provided. Using verbosity '$resolvedVerbosity' to determine default scope."
        $Scope = switch ($resolvedVerbosity) {
            'Error' { 'Path' }
            'Debug' { 'Path' }
            'Trace' { 'Path' }
            default { 'Name' }
        }
        Write-Verbose "Get-Context: Scope set to '$Scope'."
    }

    if ($Scope -notin @('Path', 'Name')) {
        Write-Warning "Get-Context: Invalid scope '$Scope' provided. Defaulting to 'Name'."
        $Scope = 'Name'
    }

    $result = if ($Context) {
        Write-Verbose "Get-Context: Using provided context: $Context"
        $Context
    }
    elseif ($Caller) {
        if ($Scope -eq 'Path') {
            Write-Verbose "Get-Context: Using caller's script path: $($Caller.ScriptName)"
            $scriptPath = if ($Caller.ScriptName) { Resolve-PathPOSIX $Caller.ScriptName } else { '' }
            $position = ''
            if ($Caller.PSObject.Properties.Match('Position').Count -gt 0 -and $Caller.Position.StartLineNumber -gt 0) {
                $position = ":$($Caller.Position.StartLineNumber):$($Caller.Position.StartColumnNumber)"
                Write-Verbose "Get-Context: Including position: $position"
            }
            "$scriptPath$position"
        }
        else {
            $functionName = if ($Caller.FunctionName -and -not ($Caller.FunctionName -match '^<.*>$')) {
                $Caller.FunctionName -replace '^Global:', ''
            }
            else {
                $Caller.FunctionName
            }
            Write-Verbose "Get-Context: Using caller's function name: $functionName"
            $functionName
        }
    }
    else {
        Write-Verbose "Get-Context: Using MyInvocation.MyCommand.Name: $($MyInvocation.MyCommand.Name)"
        $MyInvocation.MyCommand.Name
    }

    Write-Verbose "Get-Context: Final context string: $result"
    return $result
}

#endregion

#region Utilities
function Test-GetContext {
    <#
.SYNOPSIS
    Runs diagnostic tests on Get-Context function.
.DESCRIPTION
    Outputs various test cases with verbose and debug information.
.EXAMPLE
    Test-GetContext
#>
    [CmdletBinding()]
    param()

    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'

    $callStack = @(
        [PSCustomObject]@{
            ScriptName   = 'D:\Scripts\MyScript.ps1'
            FunctionName = 'Global:Test-Function'
            Position     = [PSCustomObject]@{
                StartLineNumber   = 42
                StartColumnNumber = 3
            }
        }
    )

    Write-Host "`nTest 1: Only context"
    Write-Host (Get-Context -Context "CustomContext")

    Write-Host "`nTest 2: No context, caller, scope by verbosity 'Error'"
    Write-Host (Get-Context -Caller $callStack[0] -Verbosity 'Error')

    Write-Host "`nTest 3: No context, caller, scope by verbosity 'Debug'"
    Write-Host (Get-Context -Caller $callStack[0] -Verbosity 'Debug')

    Write-Host "`nTest 4: No context, caller, scope by verbosity 'Information'"
    Write-Host (Get-Context -Caller $callStack[0] -Verbosity 'Information')

    Write-Host "`nTest 5: No context or caller, should use MyInvocation"
    Write-Host (Get-Context)

    Write-Host "`nTest 6: With duration and tag head/tail"
    Write-Host (Get-Context -Caller $callStack[0] -Verbosity 'Trace' -Duration '123ms' -TagHead '[[' -TagTail ']]')
}

#endregion
