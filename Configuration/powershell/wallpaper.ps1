try {
  if ($IsWindows) {
    # Windows: Get wallpaper path from registry
    $registryPath = 'HKCU:\Control Panel\Desktop'
    $valueName = 'Wallpaper'
    $wallpaperPath = Get-ItemPropertyValue -Path $registryPath -Name $valueName -ErrorAction Stop

    if ([string]::IsNullOrEmpty($wallpaperPath)) {
      Write-Warning 'Wallpaper path is empty or not found on Windows.'
    }
    else {
      [Environment]::SetEnvironmentVariable('WALLPAPER', $wallpaperPath, 'User')
      Write-Output "WALLPAPER environment variable set to: $wallpaperPath (Windows)"
    }
  }
  elseif ($IsLinux) {
    # Linux: Retrieve wallpaper based on desktop environment
    $desktop = $env:DESKTOP_SESSION
    if (-not $desktop) {
      $desktop = $env:XDG_CURRENT_DESKTOP
    }
    $desktop = $desktop.ToLower()

    switch -Wildcard ($desktop) {
      '*gnome*' {
        $output = & gsettings get org.gnome.desktop.background picture-uri 2>$null
        if ($output) {
          # Extract URI and convert to path
          $uri = $output.Trim("'")
          if ($uri -like 'file://*') {
            $path = $uri -replace '^file://', ''
            $env:WALLPAPER = $path
            Write-Output "WALLPAPER environment variable set to: $path (Linux GNOME)"
          }
        }
      }
      '*kde*' {
        $configPath = "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
        if (Test-Path $configPath) {
          $imageLine = Select-String -Path $configPath -Pattern 'Image=file://'
          if ($imageLine) {
            $line = $imageLine.Line
            if ($line -match 'Image=file://(.+)') {
              $path = $Matches[1]
              $env:WALLPAPER = $path
              Write-Output "WALLPAPER environment variable set to: $path (Linux KDE)"
            }
          }
        }
      }
      '*xfce*' {
        $monitor = 'monitor0'
        $workspace = 'workspace0'
        $xfcePath = "/backdrop/screen0/$monitor/$workspace/last-image"
        $output = & xfconf-query -c xfce4-desktop -p $xfcePath 2>$null
        if ($output) {
          $env:WALLPAPER = $output
          Write-Output "WALLPAPER environment variable set to: $output (Linux XFCE)"
        }
      }
      default {
        Write-Warning "Unsupported or unknown desktop environment: $desktop. Cannot retrieve wallpaper automatically."
      }
    }
  }
  else {
    Write-Warning 'Unsupported OS. This script supports only Windows and Linux.'
  }
}
catch {
  Write-Error "Failed to get or set wallpaper path: $_"
}
