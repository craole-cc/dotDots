<#
.SYNOPSIS
Sets up global treefmt configuration with PowerShell formatter from dotfiles.

.DESCRIPTION
This script sets up a global treefmt configuration that will be used by projects
that don't have their own PowerShell formatter configured. It handles cross-platform
setup and uses copying instead of symlinks on Windows for compatibility.

.NOTES
- Checks for $env:DOTS environment variable first
- Falls back to common dotfiles locations
- Uses copying on Windows instead of symlinks
- Creates necessary directories automatically
#>

function Test-IsAdmin {
  if ($PSVersionTable.PSVersion.Major -ge 6) {
    #~@ Try using PowerShell Core/7+
    if ($IsWindows) {
      $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
      $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
      return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    return $false
  }
  else {
    #~@ Check using Windows Powershell
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }
}

#~@ Determine if the current operating system is Windows
$isWin = ($PSVersionTable.PSVersion.Major -lt 6) -or
($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)

Write-Host 'Setting up global treefmt configuration...' -ForegroundColor Green

#~@ Step 1: Find dotfiles directory
$dotsPath = $null

if ($env:DOTS -and (Test-Path $env:DOTS)) {
  $dotsPath = $env:DOTS
  Write-Host "✓ Found dotfiles via DOTS environment variable: $dotsPath" -ForegroundColor Green
}
else {
  #~@ Define common dotfiles locations
  $commonPaths = @(
    'D:\Projects\GitHub\CC\.dots',
    "$HOME\.dotfiles",
    "$HOME\dotfiles",
    "$HOME\.dots"
  )

  foreach ($path in $commonPaths) {
    if (Test-Path $path) {
      $dotsPath = $path
      Write-Host "✓ Found dotfiles at: $dotsPath" -ForegroundColor Green
      break
    }
  }
}

if (-not $dotsPath) {
  Write-Error '❌ Could not find dotfiles directory. Please set DOTS environment variable or place dotfiles in a common location.'
  exit 1
}

#~@ Step 2: Verify source files exist
$sourceConfigPath = Join-Path $dotsPath 'Configuration\treefmt\config.toml'
$sourcePsfmtPath = Join-Path $dotsPath 'Bin\powershell\Utilities\psfmt.ps1'  # Assuming you'll move it here

if (-not (Test-Path $sourceConfigPath)) {
  Write-Error "❌ treefmt config not found at: $sourceConfigPath"
  exit 1
}

#~@ Step 3: Determine target directories
if ($isWin) {
  $globalConfigDir = "$env:APPDATA\treefmt"
  $globalToolsDir = "$env:USERPROFILE\.local\bin"
}
else {
  $globalConfigDir = "$HOME/.config/treefmt"
  $globalToolsDir = "$HOME/.local/bin"
}

$targetConfigPath = Join-Path $globalConfigDir 'treefmt.toml'
$targetPsfmtPath = Join-Path $globalToolsDir 'psfmt.ps1'

Write-Host "Target config directory: $globalConfigDir" -ForegroundColor Cyan
Write-Host "Target tools directory: $globalToolsDir" -ForegroundColor Cyan

#~@ Step 4: Create directories
Write-Host 'Creating directories...' -ForegroundColor Yellow
New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path $globalToolsDir -Force | Out-Null

#~@ Step 5: Create symlinks
Write-Host 'Setting up symlinks...' -ForegroundColor Yellow

#~@ Remove existing files/symlinks
if (Test-Path $targetConfigPath) { Remove-Item $targetConfigPath -Force }
if (Test-Path $targetPsfmtPath) { Remove-Item $targetPsfmtPath -Force }

if ($isWin) {
  #~@ On Windows, use cmd for more reliable symlink creation
  Write-Host 'Creating symlinks using cmd...' -ForegroundColor Gray

  #~@ Create config symlink
  $result = cmd /c "mklink `"$targetConfigPath`" `"$sourceConfigPath`"" 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Symlinked treefmt config to: $targetConfigPath" -ForegroundColor Green
  }
  else {
    Write-Warning "Failed to create config symlink: $result"
    Write-Host 'Falling back to copy...' -ForegroundColor Yellow
    Copy-Item $sourceConfigPath $targetConfigPath -Force
    Write-Host "✓ Copied treefmt config to: $targetConfigPath" -ForegroundColor Green
  }

  #~@ Create psfmt symlink if source exists
  if (Test-Path $sourcePsfmtPath) {
    $result = cmd /c "mklink `"$targetPsfmtPath`" `"$sourcePsfmtPath`"" 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "✓ Symlinked psfmt.ps1 to: $targetPsfmtPath" -ForegroundColor Green
    }
    else {
      Write-Warning "Failed to create psfmt symlink: $result"
      Write-Host 'Falling back to copy...' -ForegroundColor Yellow
      Copy-Item $sourcePsfmtPath $targetPsfmtPath -Force
      Write-Host "✓ Copied psfmt.ps1 to: $targetPsfmtPath" -ForegroundColor Green
    }
  }
}
else {
  #~@ Use ln on Unix-like systems
  ln -sf "$sourceConfigPath" "$targetConfigPath"
  Write-Host "✓ Symlinked treefmt config to: $targetConfigPath" -ForegroundColor Green

  if (Test-Path $sourcePsfmtPath) {
    ln -sf "$sourcePsfmtPath" "$targetPsfmtPath"
    Write-Host "✓ Symlinked psfmt.ps1 to: $targetPsfmtPath" -ForegroundColor Green
  }
}

#~@ Step 6: Update PATH if needed
$pathSeparator = if ($isWin) { ';' } else { ':' }
$currentPath = $env:PATH -split [regex]::Escape($pathSeparator)

if ($globalToolsDir -notin $currentPath) {
  Write-Host 'Adding tools directory to PATH...' -ForegroundColor Yellow

  if ($isWin) {
    #~@ Update PATH permanently on Windows
    $newPath = $env:PATH + ";$globalToolsDir"
    [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
    $env:PATH = $newPath
  }
  else {
    Write-Host '⚠️  Please add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):' -ForegroundColor Yellow
    Write-Host "export PATH=`"$globalToolsDir`:${PATH}`"" -ForegroundColor Cyan
  }

  Write-Host "✓ Updated PATH to include: $globalToolsDir" -ForegroundColor Green
}

Write-Host '✅ Setup complete!' -ForegroundColor Green
Write-Host ''
Write-Host "Global treefmt config: $targetConfigPath" -ForegroundColor Cyan
Write-Host "PowerShell formatter: $targetPsfmtPath" -ForegroundColor Cyan
Write-Host ''
Write-Host '📌 Benefits of symlinks:' -ForegroundColor Green
Write-Host '   • Changes to your dotfiles are automatically reflected' -ForegroundColor Gray
Write-Host '   • No need to run update scripts after making changes' -ForegroundColor Gray
Write-Host '   • Single source of truth in your dotfiles' -ForegroundColor Gray
Write-Host ''
Write-Host 'Projects without their own PowerShell formatter will now use your global configuration.' -ForegroundColor Green
