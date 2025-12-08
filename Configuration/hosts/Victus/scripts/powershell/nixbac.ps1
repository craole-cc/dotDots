#!/usr/bin/env pwsh
#~@ Backup NixOS configuration to /etc/nixos

param()

$ErrorActionPreference = "Stop"

#~@ Use existing environment variable
$hostnameVar = "$(hostname)".ToUpper() + "_CONFIG"
$SOURCE = [Environment]::GetEnvironmentVariable($hostnameVar)
$BACKUP = "/etc/nixos"
$ARCHIVE = "/archive/etc/nixos"

#~@ Validate source exists
if (-not $SOURCE -or -not (Test-Path $SOURCE)) {
    Write-Error "Configuration directory not found at $SOURCE"
    Write-Error "Expected environment variable: $hostnameVar"
    exit 1
}

#~@ Check for rsync
if (-not (Get-Command rsync -ErrorAction SilentlyContinue)) {
    Write-Error "rsync is not installed"
    exit 1
}

#~@ Archive existing /etc/nixos if it exists
if (Test-Path $BACKUP) {
    Write-Host "Archiving existing /etc/nixos..."
    
    #~@ Create archive directory
    sudo mkdir -p $ARCHIVE
    
    #~@ Get next backup number
    $existing = Get-ChildItem -Path $ARCHIVE -Directory -Filter "backup.*" -ErrorAction SilentlyContinue |
        ForEach-Object { [int]($_.Name -replace 'backup\.', '') } |
        Sort-Object -Descending |
        Select-Object -First 1
    
    $next = if ($existing) { $existing + 1 } else { 1 }
    $archiveDir = "$ARCHIVE/backup.$next"
    
    #~@ Move existing /etc/nixos to archive
    sudo mv $BACKUP $archiveDir
    Write-Host "✓ Archived to: $archiveDir" -ForegroundColor Green
}

#~@ Copy configuration to /etc/nixos
Write-Host "Copying configuration to /etc/nixos..."
sudo rsync -av --exclude='.git' "$SOURCE/" "$BACKUP/"
Write-Host "✓ Configuration copied to /etc/nixos" -ForegroundColor Green

#~@ Update nixPath in /etc/nixos/mod/system.nix (not source!)
$SYSTEM_NIX = "$BACKUP/mod/system.nix"

if (Test-Path $SYSTEM_NIX) {
    Write-Host "Updating nixPath in /etc/nixos/mod/system.nix..."
    
    try {
        #~@ Read content from the BACKUP location
        $content = Get-Content $SYSTEM_NIX -Raw
        
        #~@ Remove any existing nixos-config lines
        $content = $content -replace '(?m)^\s*(?:#\s*)?"nixos-config=.*".*$\r?\n?', ''
        
        #~@ Add new nixos-config line after nixpkgs line
        $content = $content -replace `
            '(?m)^(\s*"nixpkgs=.*")$', `
            "`$1`n      `"nixos-config=/etc/nixos/configuration.nix`""
        
        #~@ Write back to BACKUP location
        $content | sudo tee $SYSTEM_NIX | Out-Null
        
        Write-Host "✓ Updated nixPath to use /etc/nixos/configuration.nix" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update ${SYSTEM_NIX}: $_"
        exit 1
    }
} else {
    Write-Warning "$SYSTEM_NIX not found"
}

Write-Host ""
Write-Host "✓ Backup complete!" -ForegroundColor Green
Write-Host "  Configuration: /etc/nixos" -ForegroundColor Cyan
if (Test-Path $archiveDir) {
    Write-Host "  Previous backup: $archiveDir" -ForegroundColor Cyan
}
