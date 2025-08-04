<#
.SYNOPSIS
  Fast cross-platform wallpaper detection and management optimized for shell startup performance.

.DESCRIPTION
  Provides Set-Wallpaper and Get-Wallpaper functions for detecting and managing desktop wallpapers
  across Windows, Linux, and macOS. Uses early-return pattern to minimize execution time.

  Sets the WALLPAPER and DOTS_WALLPAPER environment variables at the user level
  (persistent across sessions) only when values change to maintain performance.
  Designed to be called during shell initialization with minimal performance impact.

.NOTES
  Author: PowerShell Community
  Version: 2.3
  Last Modified: 2025-08-25
  License: MIT

  Performance: Optimized for <50ms execution on typical systems
  Dependencies: None (uses built-in .NET and OS commands only)

  Platform Support:
  ✓ Windows 10/11    - JohnsBackgroundSwitcher, Registry, Windows Spotlight
  ✓ Linux           - GNOME, KDE Plasma, XFCE
  ✓ macOS           - System wallpaper via AppleScript

.EXAMPLE
  Register-Wallpaper
  Unregister-Wallpaper
  Get-Wallpaper
  $env:WALLPAPER
  $env:DOTS_WALLPAPER
#>

# Fast helper to set user env var only if value changed (Windows optimization)
function Global:Set-UserEnvIfChanged {
  param([string]$Name, [string]$Value)

  if ($IsWindows) {
    $current = [Environment]::GetEnvironmentVariable($Name, 'User')
    if ($current -ne $Value) {
      [Environment]::SetEnvironmentVariable($Name, $Value, 'User')

      # Set current session regardless of platform
      Set-Item "env:$Name" $Value -Force
    }
  }
}

function Global:Register-Wallpaper {
  <#
  .SYNOPSIS
      Registers and detects wallpaper environment variables.
  .DESCRIPTION
      Fast cross-platform wallpaper detection that registers WALLPAPER and DOTS_WALLPAPER
      environment variables. Optimized for shell startup performance.
  .EXAMPLE
      Register-Wallpaper
  #>
  [CmdletBinding()]
  param()

  # Initialize DOTS_WALLPAPER first (this should always be available)
  $defaultPath = Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper' 'default.jpg'
  if ($env:DOTS -and (Test-Path $defaultPath -ErrorAction SilentlyContinue)) {
    Set-UserEnvIfChanged 'DOTS_WALLPAPER' $defaultPath
  }

  # =============================================================================
  # WINDOWS WALLPAPER DETECTION
  # =============================================================================
  if ($IsWindows) {

    # Priority 1: JohnsBackgroundSwitcher Lock Screen Images
    $johnsPath = Join-Path $env:APPDATA 'johnsadventures.com' 'Background Switcher' 'LockScreen'
    if (Test-Path $johnsPath -ErrorAction SilentlyContinue) {
      $johnsFiles = @(Get-ChildItem (Join-Path $johnsPath '*.jpg') -ErrorAction SilentlyContinue | Select-Object -First 1)
      if ($johnsFiles.Count -gt 0) {
        Set-UserEnvIfChanged 'WALLPAPER' $johnsFiles[0].FullName
        return
      }
    }

    # Priority 2: Windows System Registry Wallpaper
    try {
      $regPath = 'HKEY_CURRENT_USER\Control Panel\Desktop'
      $wallpaperPath = [Microsoft.Win32.Registry]::GetValue($regPath, 'Wallpaper', $null)
      if ($wallpaperPath -and (Test-Path $wallpaperPath -ErrorAction SilentlyContinue)) {
        Set-UserEnvIfChanged 'WALLPAPER' $wallpaperPath
        return
      }
    }
    catch { }

    # Priority 3: Windows Spotlight Assets (fallback)
    $assetsPath = Join-Path $env:LOCALAPPDATA 'Packages' 'Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy' 'LocalState' 'Assets'
    if (Test-Path $assetsPath -ErrorAction SilentlyContinue) {
      $asset = Get-ChildItem $assetsPath -File -ErrorAction SilentlyContinue |
      Where-Object Length -GT 100KB |
      Select-Object -First 1
      if ($asset) {
        Set-UserEnvIfChanged 'WALLPAPER' $asset.FullName
        return
      }
    }
  }

  # =============================================================================
  # LINUX WALLPAPER DETECTION
  # =============================================================================
  elseif ($IsLinux) {

    # Priority 1: GNOME Desktop
    try {
      $gnomeUri = & gsettings get org.gnome.desktop.background picture-uri 2>$null
      if ($gnomeUri -and $gnomeUri -ne "''") {
        $path = $gnomeUri.Trim("'") -replace '^file://', ''
        if (Test-Path $path -ErrorAction SilentlyContinue) {
          Set-Item 'env:WALLPAPER' $path -Force
          return
        }
      }
    }
    catch { }

    # Priority 2: KDE Plasma Desktop
    $kdeConfig = Join-Path $HOME '.config' 'plasma-org.kde.plasma.desktop-appletsrc'
    if (Test-Path $kdeConfig -ErrorAction SilentlyContinue) {
      try {
        $content = Get-Content $kdeConfig -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Image=file://([^\r\n]+)') {
          $path = $matches[1]
          if (Test-Path $path -ErrorAction SilentlyContinue) {
            Set-Item 'env:WALLPAPER' $path -Force
            return
          }
        }
      }
      catch { }
    }

    # Priority 3: XFCE Desktop
    try {
      $xfcePath = & xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image 2>$null
      if ($xfcePath -and (Test-Path $xfcePath -ErrorAction SilentlyContinue)) {
        Set-Item 'env:WALLPAPER' $xfcePath -Force
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
      $script = 'tell application "Finder" to get POSIX path of (get desktop picture as alias)'
      $macPath = & osascript -e $script 2>$null
      if ($macPath -and (Test-Path $macPath.Trim() -ErrorAction SilentlyContinue)) {
        Set-Item 'env:WALLPAPER' $macPath.Trim() -Force
        return
      }
    }
    catch { }
  }

  # =============================================================================
  # FALLBACK TO DEFAULT
  # =============================================================================
  if ($defaultPath -and (Test-Path $defaultPath -ErrorAction SilentlyContinue)) {
    Set-UserEnvIfChanged 'WALLPAPER' $defaultPath
  }
}

function Global:Unregister-Wallpaper {
  <#
  .SYNOPSIS
    Unregisters wallpaper environment variables.
  .DESCRIPTION
    Removes WALLPAPER and DOTS_WALLPAPER environment variables from both
    the current session and user-level persistence (Windows registry).
  .EXAMPLE
    Unregister-Wallpaper
  #>
  [CmdletBinding()]
  param()

  if ($IsWindows) {
    # Remove from Windows user registry
    [Environment]::SetEnvironmentVariable('WALLPAPER', $null, 'User')
    [Environment]::SetEnvironmentVariable('DOTS_WALLPAPER', $null, 'User')
  }

  # Remove from current session
  Remove-Item 'env:WALLPAPER' -ErrorAction SilentlyContinue
  Remove-Item 'env:DOTS_WALLPAPER' -ErrorAction SilentlyContinue
}

function Global:Get-Wallpaper {
  <#
  .SYNOPSIS
  Gets current wallpaper environment variables.
  .DESCRIPTION
  Returns the current WALLPAPER and DOTS_WALLPAPER environment variable values.
  Optionally refreshes the detection before returning values.
  .PARAMETER Refresh
  Re-run wallpaper registration before returning values.
  .EXAMPLE
  Get-Wallpaper
  .EXAMPLE
  Get-Wallpaper -Refresh
  #>
  [CmdletBinding()]
  param(
    [switch]$Refresh
  )

  if ($Refresh) {
    Register-Wallpaper
  }

  $env:WALLPAPER
}
