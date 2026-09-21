
$ErrorActionPreference = "Stop"

if ($args.Count -eq 0) {
    exit 0
}

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Warning "PSScriptAnalyzer is not installed. Installing it now..."

    Install-PSResource `
        -Name PSScriptAnalyzer `
        -Repository PSGallery `
        -Scope CurrentUser `
        -TrustRepository `
        -Quiet
}

Import-Module PSScriptAnalyzer

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($file in $args) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        [Console]::Error.WriteLine("pwsh-format: file not found: $file")
        exit 1
    }

    $path = (Resolve-Path -LiteralPath $file).ProviderPath
    $source = [System.IO.File]::ReadAllText($path)
    $formatted = Invoke-Formatter -ScriptDefinition $source

    if ($formatted -ne $source) {
        [System.IO.File]::WriteAllText($path, $formatted, $utf8NoBom)
    }
}
