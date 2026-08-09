$ErrorActionPreference = "Stop"

if (Get-Command nix -ErrorAction SilentlyContinue) {
    nix flake check --no-build
    exit $LASTEXITCODE
}

Write-Host "Nix unavailable; run the repository's native checks here."
