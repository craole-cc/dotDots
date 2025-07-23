<#
.SYNOPSIS
Formats PowerShell scripts from stdin or files in-place using PSScriptAnalyzer's Invoke-Formatter.

.DESCRIPTION
This script formats PowerShell code by invoking PSScriptAnalyzer's Invoke-Formatter.
It supports formatting content from standard input (e.g., for editors) or files specified as parameters (formatting them in-place).
If the PSScriptAnalyzer module is not installed, it installs it into the current user's scope automatically.

It also supports customizable formatting via settings defined inline within this script.

.PARAMETER stdin
If specified, script reads PowerShell code from standard input and writes the formatted code to standard output.
Use this for external editor integrations or pipelines.

.PARAMETER FilePaths
One or more paths to PowerShell script files to be formatted in-place.

.EXAMPLE
# Format code piped via stdin (e.g. for external editor formatter):
pwsh -NoProfile -File psfmt.ps1 -stdin < script.ps1 > formatted.ps1

.EXAMPLE
# Format script files in-place:
pwsh -NoProfile -File psfmt.ps1 .\script1.ps1 .\script2.ps1

.NOTES
- Requires PowerShell 5.1 or higher.
- Automatically installs PSScriptAnalyzer if missing.
- Supports customizable formatting rules inside the script.
- Uses 2-space indentation to match VS Code preference.
#>

param (
  [switch]$stdin,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FilePaths
)

# Ensure PSScriptAnalyzer is installed
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
  Write-Verbose 'PSScriptAnalyzer not found. Installing...'
  Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber
}
Import-Module PSScriptAnalyzer -Force

# Define your formatting settings here as a hashtable to match VS Code PowerShell extension settings.
$formatSettings = @{
  IncludeRules = @(
    'PSUseCorrectCasing',
    'PSAutoCorrectAliases',
    'PSUseConstantStrings',
    'PSTrimWhitespaceAroundPipe',
    'PSWhitespaceBetweenParameters',
    'PSUseConsistentIndentation'
  )
  Rules        = @{
    PSAutoCorrectAliases          = @{ Enable = $true }
    PSTrimWhitespaceAroundPipe    = @{ Enable = $true }
    PSUseConstantStrings          = @{ Enable = $true }
    PSUseCorrectCasing            = @{ Enable = $true }
    PSWhitespaceBetweenParameters = @{ Enable = $true }
    PSUseConsistentIndentation    = @{
      Enable              = $true
      IndentationSize     = 2
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
      Kind                = 'space'
    }
  }
}

function Format-Code([string]$code) {
  return Invoke-Formatter -ScriptDefinition $code -Settings $formatSettings
}

if ($stdin) {
  # Read code from standard input, format it, write to standard output
  $code = [System.IO.StreamReader]::new([System.Console]::OpenStandardInput()).ReadToEnd()
  $formatted = Format-Code $code
  Write-Output $formatted
}
elseif ($FilePaths) {
  # Format each file in-place
  foreach ($file in $FilePaths) {
    Write-Verbose "Processing file: $file"
    try {
      $content = Get-Content -Path $file -Raw -ErrorAction Stop
      $formatted = Format-Code $content

      if ($content -ne $formatted) {
        $formatted | Set-Content -Path $file
        Write-Verbose "  Updated file: $file"
      }
      else {
        Write-Verbose "  No changes needed for file: $file"
      }
    }
    catch {
      Write-Warning "Error processing file '$file': $_"
    }
  }
}
else {
  Write-Host 'Usage:'
  Write-Host '  Format from stdin (e.g. for editor integration):'
  Write-Host '    pwsh -NoProfile -File psfmt.ps1 -stdin < file.ps1 > formatted.ps1'
  Write-Host '  Format files in-place:'
  Write-Host '    pwsh -NoProfile -File psfmt.ps1 file1.ps1 file2.ps1'
}
