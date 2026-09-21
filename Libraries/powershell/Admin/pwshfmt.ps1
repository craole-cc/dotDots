<#
.SYNOPSIS
Formats PowerShell source using PSScriptAnalyzer.

.DESCRIPTION
Formats PowerShell source using PSScriptAnalyzer's Invoke-Formatter.

The script supports two modes:

- File mode formats one or more PowerShell files in-place.
- Stdin mode reads PowerShell source from standard input and writes the
  formatted source to standard output.

PSScriptAnalyzer is provided by the surrounding Nix environment. This script
does not install, update, or otherwise modify PowerShell modules.

.PARAMETER stdin
Reads PowerShell source from standard input and writes the formatted source
to standard output.

This mode is useful for editor integrations and Unix-style pipelines.

.PARAMETER FilePaths
One or more PowerShell script paths to format in-place.

.EXAMPLE
pwsh-format script.ps1

Formats script.ps1 in-place.

.EXAMPLE
pwsh-format script1.ps1 script2.ps1

Formats multiple PowerShell files in-place.

.EXAMPLE
Get-Content script.ps1 -Raw | pwsh-format --stdin

Reads script.ps1 from standard input and writes the formatted source to
standard output.

.EXAMPLE
pwsh-format --stdin < script.ps1 > formatted.ps1

Formats a PowerShell file through standard input and writes the result to
another file.

.NOTES
Requires PSScriptAnalyzer.

PSScriptAnalyzer is supplied declaratively by Nix and is made available
through PSModulePath by the pwsh-format wrapper.

Formatting behaviour is configured in this script through $formatSettings.

The formatter writes files as UTF-8 without a BOM.

.LINK
https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/overview

.LINK
https://github.com/PowerShell/PSScriptAnalyzer
#>


[CmdletBinding()]
param(
    [switch]$stdin,

    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$FilePaths
)

$ErrorActionPreference = "Stop"

Import-Module PSScriptAnalyzer

$formatSettings = @{
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 2
            PipelineIndentation = "IncreaseIndentationForFirstPipeline"
            Kind                = "space"
        }
        PSTrimWhitespaceAroundPipe = @{
            Enable = $true
        }
        PSWhitespaceBetweenParameters = @{
            Enable = $true
        }
    }
}

function Format-Code {
    param(
        [Parameter(Mandatory)]
        [string]$Code
    )

    Invoke-Formatter `
        -ScriptDefinition $Code `
        -Settings $formatSettings
}

if ($stdin) {
    $reader = [System.IO.StreamReader]::new(
        [System.Console]::OpenStandardInput()
    )

    try {
        $source = $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }

    Format-Code $source
    exit $LASTEXITCODE
}

if ($FilePaths.Count -eq 0) {
    exit 0
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($file in $FilePaths) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        [Console]::Error.WriteLine(
            "pwsh-format: file not found: $file"
        )
        exit 1
    }

    $path = (Resolve-Path -LiteralPath $file).ProviderPath
    $source = [System.IO.File]::ReadAllText($path)

    $formatted = Format-Code $source

    if ($formatted -ne $source) {
        [System.IO.File]::WriteAllText(
            $path,
            $formatted,
            $utf8NoBom
        )
    }
}
