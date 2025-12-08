#!/usr/bin/env pwsh
<#
.SYNOPSIS
    NixOS management script: run nixos-rebuild or Nix repl with flake support.

.DESCRIPTION
    This script provides convenient aliases for NixOS operations and ensures robust flake handling.

    Features:
    - Modes: switch, boot, test, build, edit, dry-run, build-image, build-vm, build-vm-with-boot-loader, list-generations, repl
    - Additional flags:
        - NoFlake (disable flake mode for nixos-rebuild, flake is default)
        - NoTrace (disable --show-trace)
        - Pkgs (for repl only, uses remote nixpkgs)
        - Clip (copy output to clipboard, default $true for dry-run)
        - Dump (save output to file, default $true for dry-run)
        - Force (skip git clean check)
    - Hostname override allows running commands for a specific system configuration.
    - Git clean check: For rebuild operations, checks if git tree is clean before proceeding.
    - Automatic detection of a local flake:
        - Checks the current directory first.
        - Recursively searches subdirectories for a flake.nix.
        - If none found, errors out (for repl) or falls back to system flake (for rebuilds).

.EXAMPLES
    ./nixos.ps1
        Launches nix repl using the nearest local flake and the current hostname.

    ./nixos.ps1 -Switch
        Runs 'sudo nixos-rebuild switch --flake' using the system configuration for the current hostname.

    ./nixos.ps1 -Dry
        Performs a dry-run, automatically copying output to clipboard and saving to file.

    ./nixos.ps1 -Switch -Force
        Runs 'sudo nixos-rebuild switch' even if git tree is dirty.

.PARAMETER Force
    Skip git clean check for rebuild operations.
#>

param(
    [switch]$Switch,
    [switch]$Boot,
    [switch]$Test,
    [switch]$Build,
    [switch]$Edit,
    [switch]$Repl,
    [switch]$DryOnly,
    [switch]$Dry,
    [switch]$Simulate,
    [switch]$DryRun,
    [switch]$BuildImage,
    [switch]$BuildVm,
    [switch]$BuildVmWithBootLoader,
    [switch]$ListGenerations,
    [switch]$NoFlake,
    [switch]$Trace,
    [switch]$Pkgs,
    [switch]$Clip,
    [switch]$NoClip,
    [switch]$Dump,
    [switch]$NoDump,
    [switch]$Force,
    [string]$Hostname
)

# -----------------------------
# Determine mode
# -----------------------------
$mode = if ($Switch) { "switch" }
        elseif ($Boot) { "boot" }
        elseif ($Test) { "test" }
        elseif ($Build) { "build" }
        elseif ($Edit) { "edit" }
        elseif ($Dry -or $Simulate -or $DryRun -or $DryOnly) { "dry-run" }
        elseif ($BuildImage) { "build-image" }
        elseif ($BuildVm) { "build-vm" }
        elseif ($BuildVmWithBootLoader) { "build-vm-with-boot-loader" }
        elseif ($ListGenerations) { "list-generations" }
        elseif ($Repl) { "repl" }
        else { "repl" }

$isDryRun = ($mode -eq "dry-run")

# -----------------------------
# Handle Clip/Dump defaults for dry-run
# -----------------------------
$shouldClip = if ($NoClip) { $false } elseif ($Clip) { $true } elseif ($isDryRun) { $true } else { $false }
$shouldDump = if ($NoDump) { $false } elseif ($Dump) { $true } elseif ($isDryRun) { $true } else { $false }

if ($DryOnly) {
    $shouldClip = $false
    $shouldDump = $false
}

# -----------------------------
# Determine hostname
# -----------------------------
if (-not $Hostname) { $Hostname = hostname }

# -----------------------------
# Determine flake path
# -----------------------------
function Find-Flake {
    param([string]$StartDir = (Get-Location))

    if (Test-Path (Join-Path $StartDir "flake.nix")) {
        return (Resolve-Path $StartDir).Path
    }

    $flake = Get-ChildItem -Path $StartDir -Filter "flake.nix" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($flake) {
        return $flake.Directory.FullName
    }

    return $null
}

#~@ Try to use the hostname CONFIG variable first, then search
$hostnameVar = "$(hostname)".ToUpper() + "_CONFIG"
$configPath = [Environment]::GetEnvironmentVariable($hostnameVar)

if ($configPath -and (Test-Path "$configPath/flake.nix")) {
    $flakePath = $configPath
} else {
    $flakePath = Find-Flake
}

if (-not $flakePath) {
    Write-Host "Error: no flake.nix found in this directory or its subdirectories." -ForegroundColor Red
    Write-Host "Expected flake at: $configPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using flake: $flakePath" -ForegroundColor Cyan
Write-Host ""

# -----------------------------
# Check git status for rebuild operations
# -----------------------------
if ($mode -ne "repl" -and -not $Force) {
    Push-Location $flakePath

    $gitStatus = git status --porcelain 2>$null

    if ($gitStatus) {
        Write-Host "Warning: Git tree is dirty!" -ForegroundColor Yellow
        Write-Host ""
        git status --short
        Write-Host ""

        $userChoice = Read-Host "Options: [c]ommit (default), [g]itui, [f]orce continue, [a]bort"
        $userChoice = $userChoice.ToLower().Trim()

        if ($userChoice -eq '' -or $userChoice -eq 'c') {
            $message = Read-Host "Commit message"
            if ($message) {
                git add -A
                git commit -m $message
                Write-Host "✓ Changes committed" -ForegroundColor Green
            } else {
                Write-Host "Aborted: no commit message provided" -ForegroundColor Red
                Pop-Location
                exit 1
            }
        }
        elseif ($userChoice -eq 'g') {
            if (Get-Command gitui -ErrorAction SilentlyContinue) {
                gitui
                #~@ Check again after gitui
                $gitStatus = git status --porcelain 2>$null
                if ($gitStatus) {
                    Write-Host "Git tree still dirty. Aborting." -ForegroundColor Red
                    Pop-Location
                    exit 1
                }
                Write-Host "✓ Git tree is clean" -ForegroundColor Green
            } else {
                Write-Host "gitui not found. Install it or use another option." -ForegroundColor Red
                Pop-Location
                exit 1
            }
        }
        elseif ($userChoice -eq 'f') {
            Write-Host "Forcing continue with dirty tree..." -ForegroundColor Yellow
        }
        elseif ($userChoice -eq 'a') {
            Write-Host "Aborted" -ForegroundColor Red
            Pop-Location
            exit 1
        }
        else {
            Write-Host "Invalid option. Aborting." -ForegroundColor Red
            Pop-Location
            exit 1
        }
    }

    Pop-Location
}

# -----------------------------
# Determine output directory for dumps
# -----------------------------
$Hostname_VAR = (hostname).ToUpper()
$HostCacheVar = "${Hostname_VAR}_CACHE"
$ProjectCacheVar = "PROJECT_CACHE"
$ProjectTmpVar = "PROJECT_TMP"

function Get-IfVariableExists {
    param([string]$VarName)
    $var = Get-Variable -Name $VarName -ErrorAction SilentlyContinue
    if ($var) { return $var.Value }
    return $null
}

$OutputDir = if ($val = Get-IfVariableExists $ProjectCacheVar) { $val }
             elseif ($val = Get-IfVariableExists $ProjectTmpVar) { $val }
             elseif ($val = Get-IfVariableExists $HostCacheVar) { $val }
             else { Join-Path $flakePath "tmp" }

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# -----------------------------
# Build the command string
# -----------------------------
if ($mode -eq "repl") {
    $cmd = "nix repl --extra-experimental-features 'nix-command flakes'"

    if ($Pkgs) {
        $cmd += " github:nixos/nixpkgs"
    } else {
        $cmd += " ${flakePath}#nixosConfigurations.${Hostname}"
    }

} else {
    #~@ Change to flake directory for nixos-rebuild
    Push-Location $flakePath

    $cmd = "sudo nixos-rebuild $mode"
    if (-not $NoFlake) {
        $cmd += " --flake .#${Hostname}"
    }
    if ($Trace) {
        $cmd += " --show-trace"
    }
}

# -----------------------------
# Execute and capture output
# -----------------------------
Write-Host "Executing command:"
Write-Host $cmd
Write-Host ""

if ($shouldClip -or $shouldDump) {
    # Capture both stdout and stderr
    $output = & { Invoke-Expression "$cmd 2>&1" } | Out-String

    # Display output to console
    Write-Host $output

    # Save to file if requested
    if ($shouldDump) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $dumpFile = Join-Path $OutputDir "nixos-${mode}-${timestamp}.txt"
        $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($dumpFile, $output, $Utf8NoBom)
        Write-Host ""
        Write-Host "Output saved to: $dumpFile" -ForegroundColor Green
    }

    # Copy to clipboard if requested
    if ($shouldClip) {
        try {
            if ($IsWindows) {
                $output | Set-Clipboard
                Write-Host "Output copied to clipboard!" -ForegroundColor Green
            }
            elseif ($PSVersionTable.OS -match 'Darwin') {
                $output | pbcopy
                Write-Host "Output copied to clipboard!" -ForegroundColor Green
            }
            else {
                if (Get-Command wl-copy -ErrorAction SilentlyContinue) {
                    $output | wl-copy
                    Write-Host "Output copied to clipboard!" -ForegroundColor Green
                }
                elseif (Get-Command xsel -ErrorAction SilentlyContinue) {
                    $output | xsel --clipboard --input
                    Write-Host "Output copied to clipboard!" -ForegroundColor Green
                }
                else {
                    Write-Warning "No clipboard utility found. Install wl-copy (Wayland) or xsel (X11)."
                }
            }
        }
        catch {
            Write-Warning "Clipboard copy failed: $($_.Exception.Message)"
        }
    }
} else {
    # Just run the command normally
    Invoke-Expression $cmd
}

#~@ Return to original directory if we changed it
if ($mode -ne "repl") {
    Pop-Location
}
