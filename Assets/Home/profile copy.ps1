#Requires -Version 5.1

using namespace System.IO
using namespace System.Management.Automation

#region Settings

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

# Use a proper enum for verbosity levels
enum VerbosityLevel {
    Quiet = 0
    Error = 1
    Warning = 2
    Information = 3
    Debug = 4
    Trace = 5
}

# Configuration class for better structure
class DotsConfiguration {
    [VerbosityLevel]$Verbosity = [VerbosityLevel]::Warning
    [string[]]$ParentPaths = @(
        'D:/Projects/GitHub/CC',
        'D:/Configuration',
        'D:/Dotfiles',
        $env:USERPROFILE
    )
    [string[]]$TargetNames = @(
        '.dots',
        'dotDots',
        'dots',
        'dotfiles',
        'global',
        'config',
        'common'
    )
    [string[]]$MarkerFiles = @(
        '.dotsrc',
        '.git',
        'flake.nix'
    )
}

$script:Config = [DotsConfiguration]::new()

#endregion

#region Utilities

function Get-CallerContext {
    <#
    .SYNOPSIS
        Gets contextual information about the calling function or script.

    .PARAMETER Scope
        Whether to return the full path or just the name.

    .PARAMETER Caller
        The call stack frame to analyze.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [ValidateSet('Path', 'Name')]
        [string]$Scope = 'Name',

        [Parameter(Mandatory)]
        [CallStackFrame]$Caller
    )

    # Get position info if available
    $position = if ($Caller.ScriptLineNumber -gt 0) {
        ":$($Caller.ScriptLineNumber):$($Caller.ScriptColumnNumber)"
    }
    else {
        ''
    }

    # Determine context based on caller type
    $context = switch ($true) {
        # Script name with scope
        { $Caller.ScriptName } {
            $scriptPath = Resolve-PathSafely -Path $Caller.ScriptName
            switch ($Scope) {
                'Path' { $scriptPath }
                'Name' { [Path]::GetFileName($scriptPath) }
            }
        }
        # Function name (non-scriptblock)
        { $Caller.FunctionName -and $Caller.FunctionName -notmatch '^<.*>$' } {
            $Caller.FunctionName -replace '^Global:', ''
        }
        # Position-based fallback
        { $Caller.Position.StartLineNumber -and $Caller.Position.StartLineNumber -ne 0 } {
            $col = $Caller.Position.StartColumnNumber
            $row = $Caller.Position.StartLineNumber
            "Line ${row}:${col}"
        }
        # Ultimate fallback
        default {
            'Console'
        }
    }

    return "${context}${position}"
}

function ConvertTo-VerbosityInfo {
    <#
    .SYNOPSIS
        Converts various verbosity inputs to a structured verbosity object.

    .PARAMETER InputVerbosity
        The verbosity level to parse (string, int, or VerbosityLevel enum).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(ValueFromPipeline)]
        $InputVerbosity
    )

    process {
        # Verbosity mapping with proper PowerShell colors
        $verbosityMap = @{
            [VerbosityLevel]::Quiet       = @{ Level = 0; Color = 'Gray'; Tag = 'QUIET' }
            [VerbosityLevel]::Error       = @{ Level = 1; Color = 'Red'; Tag = 'ERROR' }
            [VerbosityLevel]::Warning     = @{ Level = 2; Color = 'Yellow'; Tag = 'WARN' }
            [VerbosityLevel]::Information = @{ Level = 3; Color = 'Cyan'; Tag = 'INFO' }
            [VerbosityLevel]::Debug       = @{ Level = 4; Color = 'Green'; Tag = 'DEBUG' }
            [VerbosityLevel]::Trace       = @{ Level = 5; Color = 'Magenta'; Tag = 'TRACE' }
        }

        # Use global config if not specified
        if ($null -eq $InputVerbosity) {
            $InputVerbosity = $script:Config.Verbosity
        }

        # Handle different input types
        $verbosityLevel = switch ($InputVerbosity.GetType().Name) {
            'Int32' {
                [VerbosityLevel][Math]::Max(0, [Math]::Min(5, $InputVerbosity))
            }
            'String' {
                try {
                    [VerbosityLevel]$InputVerbosity
                }
                catch {
                    # Handle legacy string mappings
                    switch ($InputVerbosity.ToUpper()) {
                        { $_ -in @('WARN', 'WARNING') } { [VerbosityLevel]::Warning }
                        { $_ -in @('INFO', 'INFORMATION') } { [VerbosityLevel]::Information }
                        default { [VerbosityLevel]::Information }
                    }
                }
            }
            'VerbosityLevel' {
                $InputVerbosity
            }
            default {
                [VerbosityLevel]::Information
            }
        }

        return $verbosityMap[$verbosityLevel]
    }
}

function Resolve-PathSafely {
    <#
    .SYNOPSIS
        Safely resolves and normalizes a file path.

    .PARAMETER Path
        The path to resolve.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path
    )

    process {
        try {
            $resolvedPath = [Path]::GetFullPath($Path)
            return $resolvedPath.Replace('\', '/')
        }
        catch {
            Write-Warning "Failed to resolve path: $Path"
            return $Path
        }
    }
}

function Write-StructuredOutput {
    <#
    .SYNOPSIS
        Writes structured output with context, verbosity, and timing information.

    .DESCRIPTION
        A more PowerShell-idiomatic logging function that supports proper parameter binding,
        pipeline input, and follows PowerShell naming conventions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string[]]$Message,

        [VerbosityLevel]$Level = [VerbosityLevel]::Information,

        [string]$Context,

        [ValidateSet('Path', 'Name')]
        [string]$ContextScope = 'Name',

        [switch]$ShowTimestamp,

        [string]$Duration,

        [switch]$HideContext,

        [switch]$HideVerbosity,

        [string]$Delimiter = "`n    "
    )

    begin {
        $messages = @()
    }

    process {
        $messages += $Message
    }

    end {
        # Check if we should output based on verbosity
        $levelInfo = ConvertTo-VerbosityInfo -InputVerbosity $Level
        $globalLevelInfo = ConvertTo-VerbosityInfo -InputVerbosity $script:Config.Verbosity

        if ($levelInfo.Level -gt $globalLevelInfo.Level) {
            return
        }

        # Build output components
        $outputParts = @()

        # Timestamp
        if ($ShowTimestamp) {
            $outputParts += Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }

        # Verbosity tag
        if (-not $HideVerbosity) {
            $outputParts += "[$($levelInfo.Tag)]"
        }

        # Context
        if (-not $HideContext) {
            if ([string]::IsNullOrEmpty($Context)) {
                $callStack = Get-PSCallStack
                if ($callStack.Count -gt 1) {
                    $caller = $callStack[1]
                    $Context = Get-CallerContext -Caller $caller -Scope $ContextScope
                }
                else {
                    $Context = 'Console'
                }
            }

            if ($Duration) {
                $Context += " ($Duration)"
            }

            $outputParts += "[$Context]"
        }

        # Combine and output
        $prefix = if ($outputParts.Count -gt 0) {
            ($outputParts -join ' ') + ': '
        }
        else {
            ''
        }

        $fullMessage = $prefix + ($messages -join $Delimiter)

        # Use appropriate Write-* cmdlet based on level
        switch ($Level) {
            ([VerbosityLevel]::Error) {
                Write-Error $fullMessage
            }
            ([VerbosityLevel]::Warning) {
                Write-Warning $fullMessage
            }
            ([VerbosityLevel]::Debug) {
                Write-Debug $fullMessage
            }
            ([VerbosityLevel]::Trace) {
                Write-Verbose $fullMessage
            }
            default {
                Write-Host $fullMessage -ForegroundColor $levelInfo.Color
            }
        }
    }
}

function Invoke-CommandWithLogging {
    <#
    .SYNOPSIS
        Executes a command with comprehensive logging and error handling.

    .PARAMETER ScriptBlock
        The script block to execute.

    .PARAMETER Name
        A friendly name for the command being executed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [string]$Name = 'Command',

        [VerbosityLevel]$Level = [VerbosityLevel]::Information,

        [switch]$PassThru
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        Write-StructuredOutput -Message "Executing: $Name" -Level Debug

        $result = & $ScriptBlock
        $stopwatch.Stop()

        $duration = "{0:F2}ms" -f $stopwatch.Elapsed.TotalMilliseconds
        Write-StructuredOutput -Message "Completed successfully" -Level $Level -Duration $duration -Context $Name

        if ($PassThru) {
            return $result
        }
    }
    catch {
        $stopwatch.Stop()
        $duration = "{0:F2}ms" -f $stopwatch.Elapsed.TotalMilliseconds

        Write-StructuredOutput -Message "Failed: $($_.Exception.Message)" -Level Error -Duration $duration -Context $Name

        if (-not $PassThru) {
            throw
        }
    }
}

#endregion

#region DOTS Management

function Find-DotsDirectory {
    <#
    .SYNOPSIS
        Locates the DOTS configuration directory using configurable search paths.

    .DESCRIPTION
        Searches through parent directories and target names to find a valid DOTS directory
        containing required marker files.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string[]]$ParentPaths = $script:Config.ParentPaths,
        [string[]]$TargetNames = $script:Config.TargetNames,
        [string[]]$MarkerFiles = $script:Config.MarkerFiles
    )

    Write-StructuredOutput -Message "Searching for DOTS directory..." -Level Debug
    Write-StructuredOutput -Message @(
        "Parent paths: $($ParentPaths -join ', ')",
        "Target names: $($TargetNames -join ', ')",
        "Marker files: $($MarkerFiles -join ', ')"
    ) -Level Trace

    foreach ($parent in $ParentPaths) {
        $resolvedParent = Resolve-PathSafely -Path $parent

        if (-not (Test-Path -Path $resolvedParent -PathType Container)) {
            Write-StructuredOutput -Message "Parent path does not exist: $resolvedParent" -Level Debug
            continue
        }

        foreach ($target in $TargetNames) {
            $candidatePath = Resolve-PathSafely -Path (Join-Path -Path $resolvedParent -ChildPath $target)

            if (-not (Test-Path -Path $candidatePath -PathType Container)) {
                Write-StructuredOutput -Message "Target path does not exist: $candidatePath" -Level Trace
                continue
            }

            # Check for marker files
            foreach ($marker in $MarkerFiles) {
                $markerPath = Resolve-PathSafely -Path (Join-Path -Path $candidatePath -ChildPath $marker)

                if (Test-Path -Path $markerPath) {
                    Write-StructuredOutput -Message "Found DOTS directory: $candidatePath" -Level Information
                    return $candidatePath
                }
            }
        }
    }

    Write-StructuredOutput -Message "No DOTS directory found in search paths" -Level Warning
    return $null
}

function Set-DotsEnvironment {
    <#
    .SYNOPSIS
        Sets the DOTS environment variables across all scopes.

    .PARAMETER DotsPath
        The path to the DOTS directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DotsPath
    )

    $resolvedPath = Resolve-PathSafely -Path $DotsPath

    try {
        # Set in all appropriate scopes
        [Environment]::SetEnvironmentVariable('DOTS', $resolvedPath, 'Process')
        $global:DOTS = $resolvedPath
        $env:DOTS = $resolvedPath

        Write-StructuredOutput -Message "DOTS environment set to: $resolvedPath" -Level Information
    }
    catch {
        Write-StructuredOutput -Message "Failed to set DOTS environment: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Import-DotsProfile {
    <#
    .SYNOPSIS
        Imports the PowerShell profile from the DOTS directory.
    #>
    [CmdletBinding()]
    param()

    if ([string]::IsNullOrEmpty($env:DOTS)) {
        throw "DOTS environment variable is not set"
    }

    $profilePath = Resolve-PathSafely -Path (Join-Path -Path $env:DOTS -ChildPath 'Configuration/powershell/profile.ps1')

    if (-not (Test-Path -Path $profilePath -PathType Leaf)) {
        throw "PowerShell profile not found: $profilePath"
    }

    try {
        # Set profile environment variables
        [Environment]::SetEnvironmentVariable('DOTS_PROFILE', $profilePath, 'Process')
        $global:DOTS_PROFILE = $profilePath
        $env:DOTS_PROFILE = $profilePath

        Write-StructuredOutput -Message "Loading PowerShell profile: $profilePath" -Level Information

        # Source the profile
        . $profilePath

        Write-StructuredOutput -Message "DOTS profile loaded successfully" -Level Information
    }
    catch {
        Write-StructuredOutput -Message "Failed to load DOTS profile: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Initialize-Dots {
    <#
    .SYNOPSIS
        Complete DOTS initialization process.
    #>
    [CmdletBinding()]
    param()

    try {
        # Find DOTS directory
        $dotsPath = Invoke-CommandWithLogging -Name 'Find-DotsDirectory' -ScriptBlock {
            Find-DotsDirectory
        } -PassThru

        if ([string]::IsNullOrEmpty($dotsPath)) {
            throw "DOTS directory not found"
        }

        # Set environment
        Invoke-CommandWithLogging -Name 'Set-DotsEnvironment' -ScriptBlock {
            Set-DotsEnvironment -DotsPath $dotsPath
        }

        # Import profile
        Invoke-CommandWithLogging -Name 'Import-DotsProfile' -ScriptBlock {
            Import-DotsProfile
        }

        Write-StructuredOutput -Message "DOTS initialization completed successfully" -Level Information
        Write-StructuredOutput -Message @(
            "DOTS: $env:DOTS",
            "DOTS_PROFILE: $env:DOTS_PROFILE"
        ) -Level Information
    }
    catch {
        Write-StructuredOutput -Message "DOTS initialization failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

#endregion

#region Main Execution

# Add functions to global scope for reusability
$global:DotsUtilities = @{
    'Find-DotsDirectory'        = ${function:Find-DotsDirectory}
    'Set-DotsEnvironment'       = ${function:Set-DotsEnvironment}
    'Import-DotsProfile'        = ${function:Import-DotsProfile}
    'Initialize-Dots'           = ${function:Initialize-Dots}
    'Write-StructuredOutput'    = ${function:Write-StructuredOutput}
    'Invoke-CommandWithLogging' = ${function:Invoke-CommandWithLogging}
}

# Initialize if running as script (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.Line -notmatch '^\s*\.') {
    try {
        # Set verbosity for demonstration
        $script:Config.Verbosity = [VerbosityLevel]::Debug

        # Initialize DOTS
        Initialize-Dots

        Write-Host "`nDOTS utilities are available in `$global:DotsUtilities" -ForegroundColor Green
        Write-Host "You can also call the functions directly: Initialize-Dots, Find-DotsDirectory, etc." -ForegroundColor Green
    }
    catch {
        Write-Error "Script execution failed: $($_.Exception.Message)"
        exit 1
    }
}
else {
    Write-Host "DOTS script dot-sourced successfully. Functions are now available in the current session." -ForegroundColor Green
    Write-Host "`nTry these commands:" -ForegroundColor Yellow
    Write-Host "  Initialize-Dots                    # Find and set up DOTS" -ForegroundColor Cyan
    Write-Host "  Find-DotsDirectory                 # Just find the DOTS directory" -ForegroundColor Cyan
    Write-Host "  Write-StructuredOutput 'Hello'     # Test the logging function" -ForegroundColor Cyan
    Write-Host "  `$script:Config.Verbosity = [VerbosityLevel]::Debug  # Change verbosity" -ForegroundColor Cyan
}

#endregion
