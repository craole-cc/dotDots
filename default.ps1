# using module "D:\Projects\GitHub\CC\.dots\Modules\powershell\TestModule\TestModule.psm1"

# $VerbosePreference = 'SilentlyContinue'
# $DebugPreference = 'SilentlyContinue'
# $InformationPreference = 'SilentlyContinue'
# $WarningPreference = 'SilentlyContinue'
# $ErrorActionPreference = 'SilentlyContinue'

if (-not (Test-Path variable:DOTS_MOD)) {
    $Global:DOTS_MOD = NormalizePath (Join-Path $DOTS "Modules")
    Write-Debug "DOTS_MOD: $Global:DOTS_MOD"
}

if (-not (Test-Path variable:DOTS_MOD_PS)) {
    $Global:DOTS_MOD_PS = NormalizePath (Join-Path $DOTS_MOD "powershell")
    Write-Debug "DOTS_MOD_PS: $Global:DOTS_MOD_PS"

    #@ Add DOTS_MOD_PS to PSModulePath (if not already there)
    if (-not ($env:PSModulePath -split ';' | Where-Object { $_ -eq $DOTS_MOD_PS })) {
        Write-Verbose "Adding $DOTS_MOD_PS to PSModulePath"
        $env:PSModulePath += ";$DOTS_MOD_PS"
    }

    #@ Import all modules
    Get-ChildItem -Path $DOTS_MOD_PS -Filter *.psm1 -Recurse | ForEach-Object {
        Import-Module $_.FullName -Force
    }
}

$Global:Verbosity = 100
# checkVerbosityConfig
# Get-Verbosity
Test-GetContext
Test-WriteOutput

# We need to see what the max verbosity is as well as the current verbosity level
# Pout -Verbosity 'Trace' -Messages 'This is a trace message'
# Pout -Verbosity 'Debug' -Messages 'This is a debug message'
# Pout -Verbosity 'Info' -Messages 'This is an informational message'
# Pout -Verbosity 'Warn' -Messages 'This is a warning message'
# Pout -Verbosity 'Error' -Messages 'This is an error message'

# Pout -Level 'Blue' -Message 'Hello, World!'
