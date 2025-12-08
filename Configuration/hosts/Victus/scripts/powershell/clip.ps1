#!/usr/bin/env pwsh
<#
Cross-platform clipboard setter:
- Windows: Set-Clipboard
- macOS: pbcopy
- Linux: wl-copy or xsel

Usage:
    ./clip.ps1 "hello"
    echo "hello" | ./clip.ps1
#>

param(
    [string]$Text
)

# If nothing passed, read from pipeline
if (-not $Text -and $MyInvocation.ExpectingInput) {
    $Text = [Console]::In.ReadToEnd()
}

if (-not $Text) {
    Write-Error "No text provided. Pass a string or pipe input."
    exit 1
}

# Windows
if ($IsWindows) {
    $Text | Set-Clipboard
    exit 0
}

# macOS
if ($PSVersionTable.OS -match "Darwin") {
    if (Get-Command pbcopy -ErrorAction SilentlyContinue) {
        $Text | pbcopy
        exit 0
    }
    Write-Error "pbcopy not found"
    exit 1
}

# Linux
if (Get-Command wl-copy -ErrorAction SilentlyContinue) {
    $Text | wl-copy
    exit 0
}
if (Get-Command xsel -ErrorAction SilentlyContinue) {
    $Text | xsel --clipboard --input
    exit 0
}

Write-Error "No clipboard utility found (install wl-copy or xsel)"
exit 1
