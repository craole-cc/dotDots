# Launch the latest PowerShell Language Server available on any platform.

# Find the newest available PowerShell executable
$pwsh = $null

if ($IsWindows) {
    $pwsh7 = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwsh7) {
        $pwsh = $pwsh7.Source
    }
    else {
        $ps5 = Get-Command powershell.exe -ErrorAction SilentlyContinue
        if ($ps5) {
            $pwsh = $ps5.Source
        }
    }
}
else {
    # On NixOS, the package is called 'powershell'
    $nixps = Get-Command powershell -ErrorAction SilentlyContinue
    if ($nixps) {
        $pwsh = $nixps.Source
    }
    else {
        $pwsh7 = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwsh7) {
            $pwsh = $pwsh7.Source
        }
    }
}

if (-not $pwsh) {
    Write-Error "No suitable PowerShell executable found."
    exit 1
}

$sessionPath = if ($IsWindows) { "$env:TEMP\pses_session.json" } else { "$HOME/.pses_session.json" }

& $pwsh -NoProfile -Command "Import-Module PowerShellEditorServices; Start-EditorServices -HostName 'zed' -HostProfileId 'zed' -HostVersion '1.0.0' -SessionDetailsPath '$sessionPath'"
