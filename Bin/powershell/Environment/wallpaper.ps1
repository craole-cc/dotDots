<#
.SYNOPSIS
  Fast, cross-platform wallpaper detection and management for shell startup.

.DESCRIPTION
  Provides functions to detect and manage desktop wallpapers across Windows, Linux, and macOS.
  It sets a persistent WALLPAPER environment variable and creates a stable symlink at
  ~/Pictures/wallpaper for easy access by other applications.

  The script is highly optimized to run during shell initialization with minimal (<50ms) impact.

.NOTES
  Author: PowerShell Community
  Version: 3.0
  License: MIT
  Platform Support: Windows, Linux (GNOME, KDE, XFCE), macOS

.EXAMPLE
  Register-Wallpaper
  # Detects wallpaper, sets the $env:WALLPAPER variable, and creates the symlink.

.EXAMPLE
  Get-Wallpaper -Refresh
  # Re-runs detection and then returns the current wallpaper path.
#>

# Helper to set user env var only if the value has changed, but always update the current session.
function Global:Set-UserEnvIfChanged {
  param([string]$Name, [string]$Value)
  # Always set the session variable for immediate use.
  Set-Item "env:$Name" $Value -Force
  # For Windows, only write to the persistent registry if the value has changed to avoid slow I/O.
  if ($IsWindows) {
    if ([Environment]::GetEnvironmentVariable($Name, 'User') -ne $Value) {
      [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    }
  }
}

# Helper to create or update the wallpaper symlink only when necessary.
function Global:Set-WallpaperSymlink {
  param([string]$NewWallpaperPath)
  $symlinkDir = if ($IsWindows) { Join-Path $env:USERPROFILE 'Pictures' } else { Join-Path $env:HOME 'Pictures' }
  $symlinkPath = Join-Path $symlinkDir 'wallpaper'

  # Get the target of the old symlink for change detection.
  $previousWallpaper = if (Test-Path $symlinkPath -EA 0) {
    try { (Get-Item $symlinkPath -EA 0).Target } catch { $null }
  }
  else { $null }

  # Only modify the file system if the wallpaper has actually changed.
  if ($previousWallpaper -ne $NewWallpaperPath) {
    if (-not (Test-Path $symlinkDir)) {
      $null = New-Item -Path $symlinkDir -ItemType Directory -Force
    }
    Remove-Item $symlinkPath -Force -EA 0
    try {
      if ($IsWindows) {
        Start-Process cmd.exe -ArgumentList "/c mklink `"$symlinkPath`" `"$NewWallpaperPath`"" -WindowStyle Hidden -Wait
      }
      else {
        & ln -sf $NewWallpaperPath $symlinkPath 2>$null
      }
    }
    catch {
      # Silent failure maintains startup performance.
    }
  }
}

# Helper to remove the wallpaper symlink.
function Global:Remove-WallpaperSymlink {
  $symlinkPath = Join-Path (if ($IsWindows) { $env:USERPROFILE } else { $env:HOME }) 'Pictures' 'wallpaper'
  if (Test-Path $symlinkPath -EA 0) {
    Remove-Item $symlinkPath -Force -EA 0
  }
}

function Global:Register-Wallpaper {
  [CmdletBinding()]
  param()

  $wallpaperPath = $null

  # Define default wallpaper, falling back to a default if one is configured.
  $dotsWallpaper = $env:DOTS_WALLPAPER
  if (-not $env:DOTS_WALLPAPER -and $env:DOTS) {
    $defaultPath = Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper' 'default.jpg'
    if (Test-Path $defaultPath -EA 0) {
      Set-UserEnvIfChanged 'DOTS_WALLPAPER' $defaultPath
      $dotsWallpaper = $defaultPath
    }
  }

  # =============================================================================
  # PLATFORM-SPECIFIC WALLPAPER DETECTION
  # =============================================================================
  if ($IsWindows) {
    #| John's Background Switcher
    $lockscreenPath = Join-Path $env:APPDATA 'johnsadventures.com' 'Background Switcher' 'LockScreen'
    if (Test-Path $lockscreenPath -EA 0) {
      $wallpaperPath = (Get-ChildItem "$lockscreenPath\*.jpg" -EA 0 | Select-Object -First 1).FullName
    }

    #| Windows Registry
    if (-not $wallpaperPath) {
      try {
        $regPath = [Microsoft.Win32.Registry]::GetValue('HKEY_CURRENT_USER\Control Panel\Desktop', 'Wallpaper', $null)
        if ($regPath -and (Test-Path $regPath -EA 0)) { $wallpaperPath = $regPath }
      }
      catch {}
    }

    #| Windows Spotlight
    if (-not $wallpaperPath) {
      $assetsPath = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
      if (Test-Path $assetsPath -EA 0) {
        $wallpaperPath = (Get-ChildItem $assetsPath -File -EA 0 | Where-Object Length -GT 100KB | Sort-Object Length -Descending | Select-Object -First 1).FullName
      }
    }
  }
  elseif ($IsLinux) {
    #| GNOME
    try {
      $uri = & gsettings get org.gnome.desktop.background picture-uri 2>$null
      $path = $uri.Trim("'") -replace '^file://'
      if ($path -and (Test-Path $path -EA 0)) { $wallpaperPath = $path }
    }
    catch {}

    #| KDE Plasma
    if (-not $wallpaperPath) {
      $kdeConfig = Join-Path $env:HOME '.config' 'plasma-org.kde.plasma.desktop-appletsrc'
      if ((Test-Path $kdeConfig -EA 0) `
          -and ((Get-Content $kdeConfig -Raw -EA 0) `
            -match 'Image=file://([^\r\n]+)')) {
        $path = $matches[1]
        if (Test-Path $path -EA 0) { $wallpaperPath = $path }
      }
    }

    #| XFCE
    if (-not $wallpaperPath) {
      try {
        $path = & xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image 2>$null
        if ($path -and (Test-Path $path -EA 0)) { $wallpaperPath = $path }
      }
      catch {}
    }
  }
  elseif ($IsMacOS) {
    try {
      $path = (& osascript -e 'tell application "Finder" to get POSIX path of (get desktop picture as alias)' 2>$null).Trim()
      if ($path -and (Test-Path $path -EA 0)) { $wallpaperPath = $path }
    }
    catch {}
  }

  # =============================================================================
  # SET VARIABLES AND SYMLINK
  # =============================================================================
  $finalWallpaperPath = if ($wallpaperPath) { $wallpaperPath } else { $dotsWallpaper }

  if ($finalWallpaperPath) {
    Set-UserEnvIfChanged 'WALLPAPER' $finalWallpaperPath
    Set-WallpaperSymlink -NewWallpaperPath $finalWallpaperPath
  }
}

function Global:Unregister-Wallpaper {
  [CmdletBinding()]
  param()
  if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('WALLPAPER', $null, 'User')
    [Environment]::SetEnvironmentVariable('DOTS_WALLPAPER', $null, 'User')
  }
  Remove-Item 'env:WALLPAPER' -EA 0
  Remove-Item 'env:DOTS_WALLPAPER' -EA 0
  Remove-WallpaperSymlink
}

function Global:Get-Wallpaper {
  [CmdletBinding()]
  param(
    [switch]$Refresh
  )
  if ($Refresh) {
    Register-Wallpaper
  }
  return $env:WALLPAPER
}
