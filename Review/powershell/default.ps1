#region Configuration

$Global:Verbosity = "Trace"
$Global:VerbosePreference = 'SilentlyContinue'
$Global:DebugPreference = 'SilentlyContinue'
$Global:InformationPreference = 'SilentlyContinue'
$Global:WarningPreference = 'SilentlyContinue'
$Global:ErrorActionPreference = 'SilentlyContinue'

#endregion
#region Environment

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
        Import-Module $_.FullName -Force `
        5>$null 4>$null 3>$null 2>$null 1>$null
    }
}

#endregion
