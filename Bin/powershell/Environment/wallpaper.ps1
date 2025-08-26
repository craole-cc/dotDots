<#
.SYNOPSIS
  Fast cross-platform wallpaper detection and management optimized for shell startup performance.

.DESCRIPTION
  Provides Register-Wallpaper, Unregister-Wallpaper and Get-Wallpaper functions for detecting and
  managing desktop wallpapers across Windows, Linux, and macOS. Uses early-return pattern and
  performance optimizations to minimize execution time.

  Sets WALLPAPER and DOTS_WALLPAPER environment variables at the user level (persistent across
  sessions) only when values change to maintain performance. Creates a portable symlink at
  USERPROFILE\wallpaper (Windows) or HOME/wallpaper (Linux/macOS) for applications that can't
  access environment variables (e.g., Windows Terminal settings).

  Designed to be called during shell initialization with minimal performance impact (<50ms).

.NOTES
  Author: PowerShell Community
  Version: 2.4
  Last Modified: 2025-08-26
  License: MIT

  Performance: Optimized for <50ms execution on typical systems
  Dependencies: None (uses built-in .NET and OS commands only)

  Platform Support:
  ✓ Windows 10/11    - JohnsBackgroundSwitcher, Registry, Windows Spotlight
  ✓ Linux           - GNOME, KDE Plasma, XFCE
  ✓ macOS           - System wallpaper via AppleScript

  Environment Variables:
  • WALLPAPER        - Current wallpaper file path
  • DOTS_WALLPAPER   - Default fallback wallpaper from dotfiles

  Symlinks Created:
  • Windows: %USERPROFILE%\wallpaper
  • Linux:   ~/wallpaper
  • macOS:   ~/wallpaper

.EXAMPLE
  Register-Wallpaper
  # Sets environment variables and creates symlink

.EXAMPLE
  Unregister-Wallpaper
  # Removes environment variables and symlink

.EXAMPLE
  Get-Wallpaper -Refresh
  # Re-detects and returns current wallpaper path
#>

# Fast helper to set user env var only if value changed (Windows optimization)
function Global:Set-UserEnvIfChanged {
  param([string]$Name, [string]$Value)

  if ($IsWindows) {
    $current = [Environment]::GetEnvironmentVariable($Name, 'User')
    if ($current -ne $Value) {
      [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
      Set-Item "env:$Name" $Value -Force
    }
  }
  else {
    # Non-Windows: just set session variable
    Set-Item "env:$Name" $Value -Force
  }
}

# Optimized helper to create wallpaper symlink (performance-focused)
function Global:Set-WallpaperSymlink {
  param()

  # Early exit if no wallpaper detected
  if (-not $env:WALLPAPER) { return }

  # Determine symlink path (minimize path operations)
  $symlinkPath = if ($IsWindows) {
    Join-Path $env:USERPROFILE 'wallpaper'
  }
  else {
    Join-Path $env:HOME 'wallpaper'
  }

  # Quick existence check and removal
  if (Test-Path $symlinkPath -ErrorAction SilentlyContinue) {
    Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
  }

  # Platform-optimized symlink creation
  try {
    if ($IsWindows) {
      # Use cmd for maximum compatibility, minimal fallback
      $null = Start-Process cmd.exe -ArgumentList "/c mklink `"$symlinkPath`" `"$env:WALLPAPER`"" -WindowStyle Hidden -Wait -PassThru
    }
    else {
      # Direct ln execution for Unix systems
      $null = & ln -sf $env:WALLPAPER $symlinkPath 2>$null
    }
  }
  catch {
    # Silent failure to maintain startup performance
  }
}

# Optimized helper to remove wallpaper symlink
function Global:Remove-WallpaperSymlink {
  param()

  $symlinkPath = if ($IsWindows) {
    Join-Path $env:USERPROFILE 'wallpaper'
  }
  else {
    Join-Path $env:HOME 'wallpaper'
  }

  if (Test-Path $symlinkPath -ErrorAction SilentlyContinue) {
    Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
  }
}

function Global:Register-Wallpaper {
  <#
  .SYNOPSIS
      Fast cross-platform wallpaper detection with symlink creation.
  .DESCRIPTION
      Detects current desktop wallpaper across Windows, Linux, and macOS platforms.
      Sets WALLPAPER and DOTS_WALLPAPER environment variables and creates a portable
      symlink for applications that can't access environment variables.

      Performance optimized for shell startup (<50ms execution time).
  .EXAMPLE
      Register-Wallpaper
      # Detects wallpaper, sets $env:WALLPAPER, creates ~/wallpaper symlink
  #>
  [CmdletBinding()]
  param()

  # Initialize DOTS_WALLPAPER (early exit optimization)
  if ($env:DOTS) {
    $defaultPath = Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper' 'default.jpg'
    if (Test-Path $defaultPath -ErrorAction SilentlyContinue) {
      Set-UserEnvIfChanged 'DOTS_WALLPAPER' $defaultPath
    }
  }

  # =============================================================================
  # WINDOWS WALLPAPER DETECTION (Priority Order)
  # =============================================================================
  if ($IsWindows) {

    # Priority 1: JohnsBackgroundSwitcher (fastest check first)
    $johnsPath = Join-Path $env:APPDATA 'johnsadventures.com\Background Switcher\LockScreen'
    if (Test-Path $johnsPath -ErrorAction SilentlyContinue) {
      $johnsFile = Get-ChildItem "$johnsPath\*.jpg" -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($johnsFile) {
        Set-UserEnvIfChanged 'WALLPAPER' $johnsFile.FullName
        Set-WallpaperSymlink
        return
      }
    }

    # Priority 2: Windows Registry (most common)
    try {
      $wallpaperPath = [Microsoft.Win32.Registry]::GetValue('HKEY_CURRENT_USER\Control Panel\Desktop', 'Wallpaper', $null)
      if ($wallpaperPath -and (Test-Path $wallpaperPath -ErrorAction SilentlyContinue)) {
        Set-UserEnvIfChanged 'WALLPAPER' $wallpaperPath
        Set-WallpaperSymlink
        return
      }
    }
    catch { }

    # Priority 3: Windows Spotlight (fallback)
    $assetsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets'
    if (Test-Path $assetsPath -ErrorAction SilentlyContinue) {
      $asset = Get-ChildItem $assetsPath -File -ErrorAction SilentlyContinue |
      Where-Object Length -GT 100KB |
      Select-Object -First 1
      if ($asset) {
        Set-UserEnvIfChanged 'WALLPAPER' $asset.FullName
        Set-WallpaperSymlink
        return
      }
    }
  }

  # =============================================================================
  # LINUX WALLPAPER DETECTION (Priority Order)
  # =============================================================================
  elseif ($IsLinux) {

    # Priority 1: GNOME (most common Linux desktop)
    try {
      $gnomeUri = & gsettings get org.gnome.desktop.background picture-uri 2>$null
      if ($gnomeUri -and $gnomeUri -ne "''") {
        $path = $gnomeUri.Trim("'") -replace '^file://', ''
        if (Test-Path $path -ErrorAction SilentlyContinue) {
          Set-Item 'env:WALLPAPER' $path -Force
          Set-WallpaperSymlink
          return
        }
      }
    }
    catch { }

    # Priority 2: KDE Plasma
    $kdeConfig = Join-Path $env:HOME '.config/plasma-org.kde.plasma.desktop-appletsrc'
    if (Test-Path $kdeConfig -ErrorAction SilentlyContinue) {
      try {
        $content = Get-Content $kdeConfig -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Image=file://([^\r\n]+)') {
          $path = $matches[1]
          if (Test-Path $path -ErrorAction SilentlyContinue) {
            Set-Item 'env:WALLPAPER' $path -Force
            Set-WallpaperSymlink
            return
          }
        }
      }
      catch { }
    }

    # Priority 3: XFCE
    try {
      $xfcePath = & xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image 2>$null
      if ($xfcePath -and (Test-Path $xfcePath -ErrorAction SilentlyContinue)) {
        Set-Item 'env:WALLPAPER' $xfcePath -Force
        Set-WallpaperSymlink
        return
      }
    }
    catch { }
  }

  # =============================================================================
  # MACOS WALLPAPER DETECTION
  # =============================================================================
  elseif ($IsMacOS) {
    try {
      $macPath = & osascript -e 'tell application "Finder" to get POSIX path of (get desktop picture as alias)' 2>$null
      if ($macPath -and (Test-Path $macPath.Trim() -ErrorAction SilentlyContinue)) {
        Set-Item 'env:WALLPAPER' $macPath.Trim() -Force
        Set-WallpaperSymlink
        return
      }
    }
    catch { }
  }

  # =============================================================================
  # FALLBACK TO DEFAULT
  # =============================================================================
  if ($env:DOTS) {
    $defaultPath = Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper' 'default.jpg'
    if (Test-Path $defaultPath -ErrorAction SilentlyContinue) {
      Set-UserEnvIfChanged 'WALLPAPER' $defaultPath
      Set-WallpaperSymlink
    }
  }
}

function Global:Unregister-Wallpaper {
  <#
  .SYNOPSIS
    Removes wallpaper environment variables and symlink.
  .DESCRIPTION
    Cleans up WALLPAPER and DOTS_WALLPAPER environment variables from both
    the current session and user-level persistence (Windows registry).
    Also removes the portable wallpaper symlink.
  .EXAMPLE
    Unregister-Wallpaper
    # Removes $env:WALLPAPER, $env:DOTS_WALLPAPER, and ~/wallpaper symlink
  #>
  [CmdletBinding()]
  param()

  # Remove persistent environment variables (Windows only)
  if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('WALLPAPER', $null, 'User')
    [Environment]::SetEnvironmentVariable('DOTS_WALLPAPER', $null, 'User')
  }

  # Remove session variables (all platforms)
  Remove-Item 'env:WALLPAPER' -ErrorAction SilentlyContinue
  Remove-Item 'env:DOTS_WALLPAPER' -ErrorAction SilentlyContinue

  # Remove symlink
  Remove-WallpaperSymlink
}

function Global:Get-Wallpaper {
  <#
  .SYNOPSIS
  Gets current wallpaper path from environment variable.
  .DESCRIPTION
  Returns the current WALLPAPER environment variable value.
  Optionally re-runs wallpaper detection before returning the value.
  .PARAMETER Refresh
  Re-run wallpaper detection before returning the path.
  .EXAMPLE
  Get-Wallpaper
  # Returns: C:\Users\User\Pictures\wallpaper.jpg
  .EXAMPLE
  Get-Wallpaper -Refresh
  # Re-detects wallpaper, then returns current path
  #>
  [CmdletBinding()]
  param(
    [switch]$Refresh
  )

  if ($Refresh) {
    Register-Wallpaper
  }

  return $env:WALLPAPER
}
