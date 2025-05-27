
$Global:Verbosity = "Trace"
$Global:VerbosePreference = 'SilentlyContinue'
$Global:DebugPreference = 'SilentlyContinue'
$Global:InformationPreference = 'SilentlyContinue'
$Global:WarningPreference = 'SilentlyContinue'
$Global:ErrorActionPreference = 'SilentlyContinue'
# $Global:VerbosePreference = 'Continue'
# $Global:DebugPreference = 'Continue'
# $Global:InformationPreference = 'Continue'
# $Global:WarningPreference = 'Continue'
# $Global:ErrorActionPreference = 'Continue'

function Set-Environment {

    #@ Validate DOTS environment variable
    if (-not $env:DOTS) {
        Write-Error "ERROR: DOTS environment variable must be set"
        exit 1
    }

    #@ Define the DOTS Binaries path globally
    $Global:DOTS_BIN = Resolve-PathPOSIX (Join-Path -Path $Global:DOTS -ChildPath 'Bin')
    [Environment]::SetEnvironmentVariable('DOTS_BIN', $Global:DOTS_BIN, 'Process')
    Set-Item -Path 'env:DOTS_BIN' -Value $Global:DOTS_BIN
    Write-Debug "DOTS_BIN => $Global:DOTS_BIN"

    #@ Define the DOTS Binaries path globally
    $Global:DOTS_BIN_PS = Resolve-PathPOSIX (Join-Path -Path $Global:DOTS_BIN -ChildPath 'powershell')
    [Environment]::SetEnvironmentVariable('DOTS_BIN_PS', $Global:DOTS_BIN_PS, 'Process')
    Set-Item -Path 'env:DOTS_BIN_PS' -Value $Global:DOTS_BIN_PS
    Write-Debug "DOTS_BIN_PS => $Global:DOTS_BIN_PS"

    #@ Define the DOTS Modules path globally
    $Global:DOTS_MOD = Resolve-PathPOSIX (Join-Path -Path $Global:DOTS -ChildPath 'Modules/')
    [Environment]::SetEnvironmentVariable('DOTS_MOD', $Global:DOTS_MOD, 'Process')
    Set-Item -Path 'env:DOTS_MOD' -Value $Global:DOTS_MOD
    Write-Debug "DOTS_MOD => $Global:DOTS_MOD"

    #@ Define the Powershell Modules path globally
    $Global:DOTS_MOD_PS = Resolve-PathPOSIX (Join-Path -Path $Global:DOTS_MOD -ChildPath 'powershell')
    [Environment]::SetEnvironmentVariable('DOTS_MOD_PS', $Global:DOTS_MOD_PS, 'Process')
    Set-Item -Path 'env:DOTS_MOD_PS' -Value $Global:DOTS_MOD_PS
    Write-Debug "DOTS_MOD_PS => $Global:DOTS_MOD_PS"
}

function Invoke-Config {

    #@ Ensure the Powershell Configuration directory was found
    if (-not $env:DOTS_CFG_PS) {
        Write-Error "ERROR: DOTS Modules directory '$DOTS_CFG_PS' does not exist"
        exit 1
    }

    #@ Add the modules to PSModulePath (if not already there)
    if (-not ($env:PSModulePath -split ';' | Where-Object { $_ -eq $DOTS_CFG_PS })) {
        Write-Verbose "Adding $DOTS_CFG_PS to PSModulePath"
        $env:PSModulePath += ";$DOTS_CFG_PS"
    }

    #@ Import all modules
    Get-ChildItem -Path $DOTS_CFG_PS -Filter *.psm1 -Recurse | ForEach-Object {
        Import-Module $_.FullName -Force
    }

    Write-Output -Tag "Information" -NoNewLine "Initialized DOTS_CFG using '${DOTS_CFG_PS}'"
}

function Invoke-Binaries {

    #@ Ensure the Powershell Modules directory was found
    if (-not $env:DOTS_BIN_PS) {
        Write-Error "ERROR: DOTS Modules directory '$DOTS_BIN_PS' does not exist"
        exit 1
    }

    #@ Add the modules to PSModulePath (if not already there)
    if (-not ($env:PSModulePath -split ';' | Where-Object { $_ -eq $DOTS_BIN_PS })) {
        Write-Verbose "Adding $DOTS_BIN_PS to PSModulePath"
        $env:PSModulePath += ";$DOTS_BIN_PS"
    }

    #@ Import all modules
    Get-ChildItem -Path $DOTS_BIN_PS -Filter *.psm1 -Recurse | ForEach-Object {
        Import-Module $_.FullName -Force
    }

    Write-Output -Tag "Information" -NoNewLine "Initialized DOTS_BIN using '${DOTS_BIN_PS}'"
}

function Invoke-Modules {

    #@ Ensure the Powershell Modules directory was found
    if (-not $env:DOTS_MOD_PS) {
        Write-Error "ERROR: DOTS Modules directory '$DOTS_MOD_PS' does not exist"
        exit 1
    }

    #@ Add the modules to PSModulePath (if not already there)
    if (-not ($env:PSModulePath -split ';' | Where-Object { $_ -eq $DOTS_MOD_PS })) {
        Write-Verbose "Adding $DOTS_MOD_PS to PSModulePath"
        $env:PSModulePath += ";$DOTS_MOD_PS"
    }

    #@ Import all modules
    Get-ChildItem -Path $DOTS_MOD_PS -Filter *.psm1 -Recurse | ForEach-Object {
        # Import-Module $_.FullName -Force 5>$null 4>$null 3>$null 2>$null 1>$null
        Import-Module $_.FullName -Force
    }

    Write-Output -Tag "Information" -NoNewLine "Initialized DOTS using '${DOTS_MOD_PS}'"
}

# Set-Environment
# Invoke-Modules
# Invoke-Binaries
# Invoke-Config
