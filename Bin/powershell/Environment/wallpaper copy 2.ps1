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
  Version: 4.2
  License: MIT
  Platform Support: Windows, Linux (GNOME, KDE, XFCE), macOS
.EXAMPLE
  Register-Wallpaper
  # Detects wallpaper, sets the $env:WALLPAPER variable, and creates the symlink.
.EXAMPLE
  Get-Wallpaper -Refresh
  # Re-runs detection and then returns the current wallpaper path.
.EXAMPLE
  Open-Wallpaper
  # Opens the current wallpaper image file with the default viewer.
#>

function Global:Register-Wallpaper {
  [CmdletBinding()]
  param()
  $wallpaperPath = $null

  # Define default wallpaper, falling back to a default if one is configured.
  $dotsWallpaper = $env:DOTS_WALLPAPER
  if (-not $env:DOTS_WALLPAPER -and $env:DOTS) {
    $defaultPath = Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper' 'default.jpg'
    if (Test-Path $defaultPath) {
      Set-UserEnvIfChanged 'DOTS_WALLPAPER' $defaultPath
      $dotsWallpaper = $defaultPath
    }
  }

  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      #| John's Background Switcher
      $jbsPath = Join-Path $env:APPDATA 'johnsadventures.com' 'Background Switcher' 'LockScreen'
      if (Test-Path $jbsPath) {
        # This is the corrected logic that finds the newest hidden wallpaper file.
        $wallpaperPath = Get-ChildItem -Path "$jbsPath\*.jpg" -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -ExpandProperty FullName -First 1
      }
      #| Windows Registry
      if (-not $wallpaperPath) {
        try {
          $regPath = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -ErrorAction Stop |
          Select-Object -ExpandProperty Wallpaper
          if ($regPath -and (Test-Path $regPath)) { $wallpaperPath = $regPath }
        }
        catch {}
      }
      #| Windows Spotlight
      if (-not $wallpaperPath) {
        $assetsPath = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
        if (Test-Path $assetsPath) {
          $wallpaperPath = Get-ChildItem $assetsPath -File -ErrorAction SilentlyContinue |
          Where-Object Length -GT 100KB |
          Sort-Object Length -Descending |
          Select-Object -ExpandProperty FullName -First 1
        }
      }
    }
    'Linux' {
      #| GNOME
      try {
        $uri = & gsettings get org.gnome.desktop.background picture-uri 2>$null
        $path = $uri.Trim("'") -replace '^file://'
        if ($path -and (Test-Path $path)) { $wallpaperPath = $path }
      }
      catch {}
      #| KDE Plasma
      if (-not $wallpaperPath) {
        $kdeConfig = Join-Path $env:HOME '.config' 'plasma-org.kde.plasma.desktop-appletsrc'
        if (Test-Path $kdeConfig) {
          $configContent = Get-Content $kdeConfig -Raw -ErrorAction SilentlyContinue
          if ($configContent -match 'Image=file://([^\r\n]+)') {
            $path = $matches[1]
            if (Test-Path $path) { $wallpaperPath = $path }
          }
        }
      }
      #| XFCE
      if (-not $wallpaperPath) {
        try {
          $path = & xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image 2>$null
          if ($path -and (Test-Path $path)) { $wallpaperPath = $path }
        }
        catch {}
      }
    }
    'MacOS' {
      try {
        $path = (& osascript -e 'tell application "Finder" to get POSIX path of (get desktop picture as alias)' 2>$null).Trim()
        if ($path -and (Test-Path $path)) { $wallpaperPath = $path }
      }
      catch {}
    }
  }

  # Use the detected wallpaper; if none was found, use the fallback.
  $finalWallpaperPath = if ($wallpaperPath) { $wallpaperPath } else { $dotsWallpaper }
  if ($finalWallpaperPath) {
    Set-UserEnvIfChanged 'WALLPAPER' $finalWallpaperPath
    Set-WallpaperSymlink -NewWallpaperPath $finalWallpaperPath
  }
}

<#
.SYNOPSIS
  Registers a list of folders to be used by the wallpaper functions.
.DESCRIPTION
  This function sets the persistent WALLPAPERS environment variable. It can be used
  to set a custom list of paths, reset to a default list, or initialize the
  variable if it's not already set.
.PARAMETER Paths
  An optional list of one or more directory paths to register. This will overwrite
  the current value of $env:WALLPAPERS.
.PARAMETER Default
  A switch that forces the function to reset the WALLPAPERS variable to its default
  state, searching for common wallpaper directories.
.EXAMPLE
  # Initializes the variable with defaults if not already set
  Register-Wallpapers

.EXAMPLE
  # Forces a reset to the default folders
  Register-Wallpapers -Default

.EXAMPLE
  # Sets the variable to a custom list of folders
  "C:\Wallpapers\Dark", "C:\Wallpapers\Light" | Register-Wallpapers
#>
function Global:Register-Wallpapers {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Paths,

    [switch]$Default
  )

  if ($Default) {
    # --- Mode 1: User specified -Default to force a reset ---
    Write-Host 'Resetting WALLPAPERS to default directories...'
    $defaultFolders = @(
      (Join-Path 'D:' 'Pictures' 'Wallpapers'),
      (Join-Path $env:USERPROFILE 'Pictures' 'Wallpapers'),
      (Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper')
    )
    $existingFolders = $defaultFolders | Where-Object { Test-Path $_ }

    if ($existingFolders) {
      $pathSeparator = [System.IO.Path]::PathSeparator
      $envValue = $existingFolders -join $pathSeparator
      Write-Host "Setting WALLPAPERS default to: $envValue"
      Set-UserEnvIfChanged -Name 'WALLPAPERS' -Value $envValue
    }
    else {
      Write-Warning 'No default wallpaper directories were found.'
    }
  }
  elseif ($PSBoundParameters.ContainsKey('Paths')) {
    # --- Mode 2: User provided paths to set the variable ---
    Write-Host 'Registering user-provided wallpaper folders...'
    $existingFolders = $Paths | Where-Object { Test-Path $_ -PathType Container }

    if ($existingFolders) {
      $pathSeparator = [System.IO.Path]::PathSeparator
      $envValue = $existingFolders -join $pathSeparator
      Write-Host "Setting WALLPAPERS to: $envValue"
      Set-UserEnvIfChanged -Name 'WALLPAPERS' -Value $envValue
    }
    else {
      Write-Warning 'None of the provided paths exist or are valid directories.'
    }
  }
  else {
    # --- Mode 3: No parameters provided, run initialization logic ---
    if (-not $env:WALLPAPERS) {
      Write-Host 'WALLPAPERS environment variable not set. Searching for default directories...'
      $defaultFolders = @(
        (Join-Path 'D:' 'Pictures' 'Wallpapers'),
        (Join-Path $env:USERPROFILE 'Pictures' 'Wallpapers'),
        (Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper')
      )
      $existingFolders = $defaultFolders | Where-Object { Test-Path $_ }

      if ($existingFolders) {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $envValue = $existingFolders -join $pathSeparator
        Write-Host "Setting WALLPAPERS default to: $envValue"
        Set-UserEnvIfChanged -Name 'WALLPAPERS' -Value $envValue
      }
    }
    else {
      Write-Host 'WALLPAPERS is already set. Use -Default to reset or -Paths to override.'
    }
  }
}

function Global:Unregister-Wallpaper {
  [CmdletBinding()]
  param()
  if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('WALLPAPER', $null, 'User')
    [Environment]::SetEnvironmentVariable('DOTS_WALLPAPER', $null, 'User')
  }
  Remove-Item 'env:WALLPAPER' -ErrorAction SilentlyContinue
  Remove-Item 'env:DOTS_WALLPAPER' -ErrorAction SilentlyContinue
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

function Global:Open-Wallpaper {
  [CmdletBinding()]
  param()
  $wallpaperPath = Get-Wallpaper
  # First, validate that a wallpaper is set and the file actually exists.
  if (-not $wallpaperPath -or -not (Test-Path $wallpaperPath)) {
    Write-Warning 'Wallpaper path is not set or the file does not exist.'
    return
  }

  # Use the appropriate command based on the OS.
  if ($IsWindows) {
    # 'Start-Process' on Windows is equivalent to double-clicking the file.
    Start-Process -FilePath $wallpaperPath
  }
  elseif ($IsLinux) {
    # Different Linux desktop environments use different default openers. This array provides a
    # fallback mechanism to find an available command ('xdg-open' is the most common).
    $openers = @('xdg-open', 'gio', 'gnome-open')
    foreach ($opener in $openers) {
      if (Get-Command $opener -ErrorAction SilentlyContinue) {
        Start-Process $opener $wallpaperPath
        return # Exit after the first successful open.
      }
    }
    Write-Warning 'No known opener found to open the wallpaper image.'
  }
  elseif ($IsMacOS) {
    # The 'open' command on macOS is the standard way to open files with their default application.
    Start-Process -FilePath 'open' -ArgumentList $wallpaperPath
  }
}

<#
.SYNOPSIS
  (Internal) Attempts to change the wallpaper using John's Background Switcher.
.DESCRIPTION
  A helper function that checks for JBS and either launches it or sends the
  "Next Picture" shortcut. Returns a boolean indicating success or failure.
.RETURNS
  [bool]$true if the action was successfully triggered, otherwise [bool]$false.
#>
function Global:Set-WallpaperWithJBS {
  [CmdletBinding()]
  param()

  # Check if John's Background Switcher is already running.
  $jbsProcess = Get-Process -Name 'BackgroundSwitcher' -ErrorAction SilentlyContinue
  if ($jbsProcess) {
    # --- JBS IS RUNNING: Send the keyboard shortcut ---
    try {
      Write-Host "JBS is running. Sending 'Next Picture' shortcut (Ctrl+Alt+N)..."
      Add-Type -AssemblyName System.Windows.Forms
      $shell = New-Object -ComObject 'Shell.Application'; $shell.MinimizeAll()
      Start-Sleep -Milliseconds 250
      [System.Windows.Forms.SendKeys]::SendWait('^%n')
      Write-Host 'Wallpaper change triggered. JBS will update the environment.' -ForegroundColor Green
      return $true
    }
    catch {
      Write-Warning 'An error occurred while trying to send the keyboard shortcut.'
      return $false
    }
  }
  else {
    # --- JBS IS NOT RUNNING: Launch the application ---
    $jbsExe = @(
      (Join-Path $env:ProgramFiles 'johnsadventures.com' "John's Background Switcher" 'BackgroundSwitcher.exe'),
      (Join-Path ${env:ProgramFiles(x86)} 'johnsadventures.com' "John's Background Switcher" 'BackgroundSwitcher.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($jbsExe) {
      try {
        Write-Host 'JBS is not running. Launching the application...'
        Start-Process $jbsExe -ErrorAction Stop
        Write-Host 'Wallpaper change triggered. JBS will update the environment.' -ForegroundColor Green
        return $true
      }
      catch {
        Write-Warning "An error occurred while trying to launch John's Background Switcher."
        return $false
      }
    }
  }
  # JBS was not found at all.
  return $false
}

<#
.SYNOPSIS
  Sets a random wallpaper from a list of specified folders.
.DESCRIPTION
  Searches for images in the provided directories (or defaults to $env:WALLPAPERS),
  picks one at random, and sets it as the desktop background.
.PARAMETER Folders
  An optional array of paths to search for wallpapers. If not provided, it uses the
  paths defined in the $env:WALLPAPERS environment variable.
.EXAMPLE
  # Use the default folders from the environment variable
  Set-RandomWallpaper

.EXAMPLE
  # Specify custom folders without using the -Folders parameter name
  Set-RandomWallpaper "C:\My Pictures", "D:\Art\Digital"
#>
function Global:Set-RandomWallpaper {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [string[]]$Folders
  )

  $foldersToSearch = @()

  if ($PSBoundParameters.ContainsKey('Folders')) {
    # If paths are provided, this block runs.
    $foldersToSearch = $Folders
  }
  else {
    # If no paths are provided, this default block runs.
    Register-Wallpapers
    $foldersToSearch = $env:WALLPAPERS -split [System.IO.Path]::PathSeparator
  }

  Write-Host 'Searching for a random wallpaper in specified folders...'
  $validFolders = $foldersToSearch | Where-Object { Test-Path $_ }

  if (-not $validFolders) {
    Write-Warning 'None of the specified wallpaper folders were found.'
    return $false
  }

  $randomImage = Get-ChildItem -Path $validFolders -Recurse -Include '*.jpg', '*.jpeg', '*.png', '*.webp' |
  Get-Random -ErrorAction SilentlyContinue

  if ($randomImage) {
    # Use the existing Set-Wallpaper function to apply the change and update the environment.
    Set-Wallpaper -FilePath $randomImage.FullName
    return $true
  }

  Write-Warning 'No image files were found in the specified folders.'
  return $false
}

<#
.SYNOPSIS
  Creates or updates the wallpaper symbolic link.
.DESCRIPTION
  Manages a symlink at '~/Pictures/wallpaper' pointing to the wallpaper image file.
  It's optimized to perform filesystem operations only when the wallpaper path has changed,
  minimizing I/O and improving startup performance.
.PARAMETER NewWallpaperPath
  The absolute path to the target wallpaper image file.
#>
function Global:Set-WallpaperSymlink {
  [CmdletBinding()]
  param(
    [string]$NewWallpaperPath
  )
  $symlinkDir = if ($IsWindows) { Join-Path $env:USERPROFILE 'Pictures' } else { Join-Path $env:HOME 'Pictures' }
  $symlinkPath = Join-Path $symlinkDir 'wallpaper'

  # Get the target of the old symlink for change detection.
  $previousWallpaper = try {
    (Get-Item $symlinkPath -ErrorAction Stop).Target
  }
  catch {
    $null
  }

  # Only modify the file system if the wallpaper has actually changed.
  if ($previousWallpaper -ne $NewWallpaperPath) {
    if (-not (Test-Path $symlinkDir)) {
      $null = New-Item -Path $symlinkDir -ItemType Directory -Force
    }
    try {
      # Use PowerShell's native, cross-platform cmdlet to create/update the symlink.
      $null = New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $NewWallpaperPath -Force
      Set-UserEnvIfChanged 'WALLPAPER_LINK' $symlinkPath
    }
    catch {
      # Silent failure maintains startup performance.
    }
  }
}

<#
.SYNOPSIS
  Removes the wallpaper symlink.
.DESCRIPTION
  A helper function to clean up by deleting the '~/Pictures/wallpaper' symlink if it exists.
#>
function Global:Remove-WallpaperSymlink {
  [CmdletBinding()]
  param()
  $symlinkDir = if ($IsWindows) { Join-Path $env:USERPROFILE 'Pictures' } else { Join-Path $env:HOME 'Pictures' }
  $symlinkPath = Join-Path $symlinkDir 'wallpaper'
  if (Test-Path $symlinkPath) {
    Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
  }
}

<#
.SYNOPSIS
  Sets a user-level environment variable efficiently.
.DESCRIPTION
  This helper updates an environment variable in the current session and, on Windows, only
  writes to the persistent user environment (registry) if the value has changed.
  This avoids slow disk I/O, making it ideal for shell startup scripts.
.PARAMETER Name
  The name of the environment variable.
.PARAMETER Value
  The value to assign to the environment variable.
#>
function Global:Set-UserEnvIfChanged {
  [CmdletBinding()]
  param(
    [string]$Name,
    [string]$Value
  )
  # Always set the session variable for immediate use.
  Set-Item -Path "env:$Name" -Value $Value -Force
  # On Windows, using the .NET method is the most performant way to handle the persistent user registry.
  if ($IsWindows) {
    if ([Environment]::GetEnvironmentVariable($Name, 'User') -ne $Value) {
      [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    }
  }
}

function Global:Debug-RegisterWallpaper {
  [CmdletBinding()]
  param()

  # Force verbose output for this function, then restore the user's original setting.
  $oldPreference = $VerbosePreference
  $VerbosePreference = 'Continue'

  try {
    Write-Verbose '--- STARTING WALLPAPER DETECTION ---'
    $wallpaperPath = $null

    # 1. Check for a fallback wallpaper first
    $dotsWallpaper = $env:DOTS_WALLPAPER
    if (-not $env:DOTS_WALLPAPER -and $env:DOTS) {
      $defaultPath = Join-Path $env:DOTS 'Assets' 'Images' 'wallpaper' 'default.jpg'
      if (Test-Path $defaultPath) {
        $dotsWallpaper = $defaultPath
      }
    }
    Write-Verbose "Fallback wallpaper is set to: '$dotsWallpaper'"

    # 2. Platform-Specific Detection
    if ($IsWindows) {
      Write-Verbose '[OS: Windows] Starting detection methods...'

      #--- Method 1: John's Background Switcher ---
      $jbsPath = Join-Path $env:APPDATA 'johnsadventures.com' 'Background Switcher' 'LockScreen'
      Write-Verbose "Checking for JBS at path: '$jbsPath'"
      if (Test-Path $jbsPath) {
        $jbsFile = Get-ChildItem -Path "$jbsPath\*.jpg" -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
        if ($jbsFile) {
          $wallpaperPath = $jbsFile.FullName
          Write-Verbose "  [SUCCESS] Found JBS wallpaper: '$wallpaperPath'"
        }
        else {
          Write-Verbose '  [FAIL] JBS directory exists, but no .jpg file was found.'
        }
      }
      else {
        Write-Verbose '  [FAIL] JBS directory not found.'
      }

      #--- Method 2: Windows Registry ---
      if (-not $wallpaperPath) {
        Write-Verbose 'Checking Windows Registry...'
        try {
          $regPath = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -ErrorAction Stop |
          Select-Object -ExpandProperty Wallpaper
          Write-Verbose "  Registry key 'Wallpaper' has value: '$regPath'"
          if ($regPath -and (Test-Path $regPath)) {
            $wallpaperPath = $regPath
            Write-Verbose "  [SUCCESS] Found valid wallpaper in registry: '$wallpaperPath'"
          }
          else {
            Write-Verbose '  [FAIL] Registry path is invalid or file does not exist.'
          }
        }
        catch {
          Write-Verbose "  [FAIL] Could not read the registry key. Error: $($_.Exception.Message)"
        }
      }

      #--- Method 3: Windows Spotlight ---
      if (-not $wallpaperPath) {
        $assetsPath = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
        Write-Verbose "Checking for Windows Spotlight at path: '$assetsPath'"
        if (Test-Path $assetsPath) {
          $spotlightFile = Get-ChildItem $assetsPath -File -ErrorAction SilentlyContinue |
          Where-Object Length -GT 100KB |
          Sort-Object Length -Descending |
          Select-Object -First 1
          if ($spotlightFile) {
            $wallpaperPath = $spotlightFile.FullName
            Write-Verbose "  [SUCCESS] Found Spotlight wallpaper: '$wallpaperPath'"
          }
          else {
            Write-Verbose '  [FAIL] Spotlight asset folder exists, but no suitable image was found.'
          }
        }
        else {
          Write-Verbose '  [FAIL] Spotlight asset folder not found.'
        }
      }
    }
    else {
      Write-Verbose "[OS: $($PSVersionTable.OS)] Skipping Windows detection."
    }

    # 3. Final Decision
    Write-Verbose '--- DETECTION COMPLETE ---'
    Write-Verbose "Detected Path: '$wallpaperPath'"
    Write-Verbose "Fallback Path: '$dotsWallpaper'"

    $finalWallpaperPath = if ($wallpaperPath) { $wallpaperPath } else { $dotsWallpaper }

    if ($finalWallpaperPath) {
      Write-Verbose "Final decision: Using '$finalWallpaperPath'."
      # Set-UserEnvIfChanged 'WALLPAPER' $finalWallpaperPath
      # Set-WallpaperSymlink -NewWallpaperPath $finalWallpaperPath
      Write-Verbose '(Variable and symlink creation disabled for this debug run)'
    }
    else {
      Write-Verbose 'Final decision: No valid wallpaper found.'
    }
    Write-Verbose '--------------------------'
  }
  finally {
    # Restore the original preference, no matter what happened.
    $VerbosePreference = $oldPreference
  }
}

<#
.SYNOPSIS
  Triggers John's Background Switcher to advance to the next wallpaper.
.DESCRIPTION
  This function programmatically triggers a wallpaper change in JBS. It checks if JBS
  is running and either sends the "Next Picture" keyboard shortcut (Ctrl+Alt+N) or
  launches the application.

  It assumes JBS is configured to automatically run Register-Wallpaper after a change.
.EXAMPLE
  Invoke-WallpaperChange
  # Checks if JBS is running, then either sends a shortcut or starts the app.
#>
function Global:Invoke-WallpaperChange {
  [CmdletBinding()]
  param()

  $success = $false

  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      # Check if John's Background Switcher is already running.
      $jbsProcess = Get-Process -Name 'BackgroundSwitcher' -ErrorAction SilentlyContinue

      if ($jbsProcess) {
        # --- JBS IS RUNNING: Send the keyboard shortcut ---
        try {
          Write-Host "JBS is running. Sending 'Next Picture' shortcut (Ctrl+Alt+N)..."
          Add-Type -AssemblyName System.Windows.Forms
          $shell = New-Object -ComObject 'Shell.Application'
          $shell.MinimizeAll()
          Start-Sleep -Milliseconds 250
          [System.Windows.Forms.SendKeys]::SendWait('^%n')
          $success = $true
        }
        catch {
          Write-Warning 'An error occurred while trying to send the keyboard shortcut.'
        }
      }
      else {
        # --- JBS IS NOT RUNNING: Launch the application ---
        $jbsExePaths = @(
          (Join-Path $env:ProgramFiles 'johnsadventures.com' "John's Background Switcher" 'BackgroundSwitcher.exe'),
          (Join-Path ${env:ProgramFiles(x86)} 'johnsadventures.com' "John's Background Switcher" 'BackgroundSwitcher.exe')
        )
        $jbsExe = $jbsExePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($jbsExe) {
          try {
            Write-Host 'JBS is not running. Launching the application...'
            Start-Process $jbsExe -ErrorAction Stop
            $success = $true
          }
          catch {
            Write-Warning "An error occurred while trying to launch John's Background Switcher."
          }
        }
        else {
          Write-Warning "John's Background Switcher executable not found."
        }
      }
    }
    default {
      Write-Warning "This functionality is only supported for John's Background Switcher on Windows."
    }
  }

  if ($success) {
    # JBS is configured to run Register-Wallpaper automatically in a separate process.
    Write-Host 'Wallpaper change triggered successfully.' -ForegroundColor Green
    Write-Host 'NOTE: Please open a new terminal to see the updated environment.' -ForegroundColor Yellow
  }
}
