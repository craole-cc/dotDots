param(
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$FilePaths
)

foreach ($file in $FilePaths) {
    Write-Host "Processing file: $file"

    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Host "PSScriptAnalyzer not found. Installing..."
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module PSScriptAnalyzer -Force
    $content = Get-Content -Path $file -Raw
    Write-Host "Original content length: $($content.Length)"

    $formatted = Invoke-Formatter -ScriptDefinition $content
    Write-Host "Formatted content length: $($formatted.Length)"

    if ($content -ne $formatted) {
        Write-Host "Content changed. Updating file: $file"
        $formatted | Set-Content -Path $file
    }
    else {
        Write-Host "No changes needed for file: $file"
    }
}
