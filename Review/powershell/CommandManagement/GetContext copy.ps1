function Global:GetContext {
    <#
    .SYNOPSIS
        Resolves and formats a context string for logging/output, with scope and verbosity awareness.
    .DESCRIPTION
        Determines the context to display (e.g., function name, script path, or custom string),
        optionally wraps it with tag head/tail, and appends duration if provided.
    .PARAMETER Caller
        Optional: The caller object from the call stack.
    .PARAMETER Context
        A custom context string to display. If not provided, uses caller or invocation info.
    .PARAMETER Scope
        'Path' to use the script path, 'Name' to use the function name. Defaults by verbosity.
    .PARAMETER Verbosity
        The verbosity level to use for default scope selection.
    .PARAMETER Duration
        Optional: Duration string to append.
    .PARAMETER TagHead
        Optional: Tag prefix (e.g., '>>=').
    .PARAMETER TagTail
        Optional: Tag suffix (e.g., '=<<').
    .EXAMPLE
        GetContext -Verbosity 'Error' -Caller $callStack[1] -Duration '15ms'
    #>
    [CmdletBinding()]
    param(
        [string]$Context,
        [string]$Scope,
        [string]$Verbosity = (Get-VerbosityDefault),
        [string]$Duration,
        [string]$TagHead = '>>=',
        [string]$TagTail = '=<<',
        $Caller
    )

    Write-Verbose "Importing GetContext"
    Write-Debug   "Caller: $($Caller | Out-String), Context='$Context', Scope='$Scope', Verbosity='$Verbosity', Duration='$Duration', TagHead='$TagHead', TagTail='$TagTail'"

    if (-not $Scope) {
        $resolvedVerbosity = Set-Verbosity $Verbosity
        Write-Warning "Scope not provided. Using verbosity '$resolvedVerbosity' to determine default scope."
        $Scope = switch ($resolvedVerbosity) {
            'Error' { 'Path' }
            'Debug' { 'Path' }
            'Trace' { 'Path' }
            default { 'Name' }
        }
        Write-Verbose "Scope set to '$Scope'."
    }

    if ($Scope -notin @('Path', 'Name')) {
        Write-Warning "Invalid scope '$Scope' provided. Defaulting to 'Name'."
        $Scope = 'Name'
    }

    $result = if ($Context) {
        Write-Verbose "Using provided context: $Context"
        $Context
    }

    elseif ($Caller) {
        if ($Scope -eq 'Path') {
            Write-Verbose "Using caller's script path: $($Caller.ScriptName)"
            $scriptPath = if ($Caller.ScriptName) { NormalizePath $Caller.ScriptName } else { '' }
            $position = ''
            if ($Caller.PSObject.Properties.Match('Position').Count -gt 0 -and $Caller.Position.StartLineNumber -gt 0) {
                $position = ":$($Caller.Position.StartLineNumber):$($Caller.Position.StartColumnNumber)"
                Write-Verbose "Including position: $position"
            }
            "$scriptPath$position"
        }
        else {
            #@ Suppress Global: prefix and angle-bracketed names
            $functionName = if ($Caller.FunctionName -and -not ($Caller.FunctionName -match '^<.*>$')) {
                $Caller.FunctionName -replace '^Global:', ''
            } else {
                $Caller.FunctionName
            }
            Write-Verbose "Using caller's function name: $functionName"
            $functionName
        }
    }
    else {
        Write-Verbose "Using MyInvocation.MyCommand.Name: $($MyInvocation.MyCommand.Name)"
        $MyInvocation.MyCommand.Name
    }

    if ($Duration) {
        Write-Verbose "Appending duration: $Duration"
        # $result += "  $Duration"
        $result += " 󱇻 $Duration"
    }

    if ($TagHead -and $TagTail) {
        Write-Verbose "Wrapping context with TagHead/TagTail: $TagHead ... $TagTail"
        return "$TagHead $result $TagTail"
    }

    Write-Verbose "Final context string: $result"
    return $result
}

function Global:Test-GetContext {
    <#
    .SYNOPSIS
        Runs diagnostic tests on GetContext function.
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
        [PSCustomObject]@{ ScriptName = 'D:\Scripts\MyScript.ps1'; FunctionName = 'Test-Function' }
    )

    Write-Host "`nTest 1: Only context"
    Write-Host (GetContext -Context "CustomContext")

    Write-Host "`nTest 2: No context, caller, scope by verbosity 'Error'"
    Write-Host (GetContext -Caller $callStack[0] -Verbosity 'Error')

    Write-Host "`nTest 3: No context, caller, scope by verbosity 'Debug'"
    Write-Host (GetContext -Caller $callStack[0] -Verbosity 'Debug')

    Write-Host "`nTest 4: No context, caller, scope by verbosity 'Information'"
    Write-Host (GetContext -Caller $callStack[0] -Verbosity 'Information')

    Write-Host "`nTest 5: No context or caller, should use MyInvocation"
    Write-Host (GetContext)

    Write-Host "`nTest 6: With duration and tag head/tail"
    Write-Host (GetContext -Caller $callStack[0] -Verbosity 'Trace' -Duration '123ms')
    # Write-Host (GetContext -Caller $callStack[0] -Verbosity 'Trace' -Duration '123ms' -TagHead '[[' -TagTail ']]')
}
