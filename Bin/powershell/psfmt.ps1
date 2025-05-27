<#
.SYNOPSIS
Formats PowerShell scripts either from standard input (for editors like Zed) or in-place (for manual use).

.DESCRIPTION
This script uses PSScriptAnalyzer's Invoke-Formatter to format PowerShell code. It can read from stdin for editor integration or format files in-place for command-line use. If PSScriptAnalyzer is not installed, it will install it automatically for the current user.

.PARAMETER stdin
When specified, reads PowerShell code from stdin and writes formatted code to stdout. Use this for editor integration (e.g., Zed's external formatter).

.PARAMETER FilePaths
One or more file paths to format in-place. If omitted and stdin is not specified, displays usage instructions.

.EXAMPLE
Format code from stdin (for Zed):
    pwsh -NoProfile -File psfmt.ps1 -stdin

.EXAMPLE
Format files in-place:
    pwsh -NoProfile -File psfmt.ps1 file1.ps1 file2.ps1

.NOTES
Requires PowerShell 5.1 or later. PSScriptAnalyzer will be installed automatically if missing.
#>
param(
    [switch]$stdin,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FilePaths
)

#@ Ensure PSScriptAnalyzer is installed
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Debug "PSScriptAnalyzer not found. Installing..."
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber
}
Import-Module PSScriptAnalyzer -Force

if ($stdin) {
    #@ Read from stdin, format, and write to stdout (for editor integration)
    $code = [System.IO.StreamReader]::new([System.Console]::OpenStandardInput()).ReadToEnd()
    $formatted = Invoke-Formatter -ScriptDefinition $code
    Write-Pretty $formatted
}
elseif ($FilePaths) {
    #@ Format each file in-place (for manual use)
    foreach ($file in $FilePaths) {
        Write-Debug "Processing file: $file"
        try {
            $content = Get-Content -Path $file -Raw -ErrorAction Stop
            $formatted = Invoke-Formatter -ScriptDefinition $content
            if ($content -ne $formatted) {
                $formatted | Set-Content -Path $file
                Write-Debug "  Updated file: $file"
            }
            else {
                Write-Debug "  No changes needed for file: $file"
            }
        }
        catch {
            Write-Host "  Error processing file: $file"
            Write-Host "  $_"
        }
    }
}
else {
    #@ Display usage instructions if no parameters are provided
    Write-Host "Usage:"
    Write-Host "  To format stdin for editors (e.g., Zed):"
    Write-Host "    pwsh -NoProfile -File psfmt.ps1 -stdin"
    Write-Host "  To format files in-place:"
    Write-Host "    pwsh -NoProfile -File psfmt.ps1 file1.ps1 file2.ps1"
}
