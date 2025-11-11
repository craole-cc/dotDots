function Global:Get-DesktopColorMode {
  <#
  .SYNOPSIS
    Detects the system's color theme (Light or Dark) across Windows, Linux, and macOS.
  .DESCRIPTION
    Queries the operating system to determine if the user is using a light or dark theme.
    Returns 'Light', 'Dark', or 'Unknown' if detection fails.
  .EXAMPLE
    Get-DesktopColorMode
    # Returns: 'Dark'
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param()

  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      try {
        # Check Windows theme via registry
        # AppsUseLightTheme: 0 = Dark, 1 = Light
        $registryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $value = Get-ItemProperty -Path $registryPath -Name 'AppsUseLightTheme' -ErrorAction Stop |
        Select-Object -ExpandProperty 'AppsUseLightTheme'

        if ($value -eq 0) {
          return 'Dark'
        }
        else {
          return 'Light'
        }
      }
      catch {
        Write-Verbose "Failed to detect Windows theme: $($_.Exception.Message)"
        return 'Unknown'
      }
    }

    'Linux' {
      # Try GNOME first (most common)
      if (Get-Command gsettings -ErrorAction SilentlyContinue) {
        try {
          $gtkTheme = & gsettings get org.gnome.desktop.interface gtk-theme 2>$null
          if ($gtkTheme -match 'dark|adwaita-dark') {
            return 'Dark'
          }
          elseif ($gtkTheme) {
            return 'Light'
          }
        }
        catch {
          Write-Verbose "Failed to get GNOME theme: $($_.Exception.Message)"
        }
      }

      # Try KDE Plasma
      $kdeGlobalsPath = [IO.Path]::Combine($env:HOME, '.config', 'kdeglobals')
      if (Test-Path $kdeGlobalsPath) {
        try {
          $kdeConfig = Get-Content $kdeGlobalsPath -Raw -ErrorAction Stop
          if ($kdeConfig -match 'ColorScheme=.*[Dd]ark') {
            return 'Dark'
          }
          elseif ($kdeConfig -match 'ColorScheme=') {
            return 'Light'
          }
        }
        catch {
          Write-Verbose "Failed to read KDE config: $($_.Exception.Message)"
        }
      }

      # Try XFCE
      if (Get-Command xfconf-query -ErrorAction SilentlyContinue) {
        try {
          $xfceTheme = & xfconf-query -c xsettings -p /Net/ThemeName 2>$null
          if ($xfceTheme -match 'dark') {
            return 'Dark'
          }
          elseif ($xfceTheme) {
            return 'Light'
          }
        }
        catch {
          Write-Verbose "Failed to get XFCE theme: $($_.Exception.Message)"
        }
      }

      # Fallback: Check GTK theme file
      $gtkConfigPath = [IO.Path]::Combine($env:HOME, '.config', 'gtk-3.0', 'settings.ini')
      if (Test-Path $gtkConfigPath) {
        try {
          $gtkConfig = Get-Content $gtkConfigPath -Raw -ErrorAction Stop
          if ($gtkConfig -match 'gtk-theme-name\s*=\s*.*[Dd]ark') {
            return 'Dark'
          }
          elseif ($gtkConfig -match 'gtk-theme-name\s*=') {
            return 'Light'
          }
        }
        catch {
          Write-Verbose "Failed to read GTK config: $($_.Exception.Message)"
        }
      }

      Write-Verbose 'Could not detect Linux desktop theme'
      return 'Unknown'
    }

    'Darwin' {
      # macOS
      try {
        $result = & defaults read -g AppleInterfaceStyle 2>$null
        if ($result -eq 'Dark') {
          return 'Dark'
        }
        else {
          # If the key doesn't exist or returns empty, it's Light mode
          return 'Light'
        }
      }
      catch {
        # If the command fails or key doesn't exist, assume Light mode (macOS default)
        Write-Verbose 'macOS theme detection returned no value, assuming Light mode'
        return 'Light'
      }
    }

    default {
      Write-Verbose "Unsupported operating system: $($PSVersionTable.OS)"
      return 'Unknown'
    }
  }
}
