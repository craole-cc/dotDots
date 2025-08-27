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
  Version: 4.4
  License: MIT
  Platform Support: Windows, Linux (GNOME, KDE, XFCE), macOS
.EXAMPLE
  Register-Wallpaper
  # Detects the current wallpaper and sets the $env:WALLPAPER variable.

.EXAMPLE
  Set-Wallpaper "C:\path\to\image.jpg"
  # Changes the wallpaper and updates the environment.
.EXAMPLE
  Set-Wallpapers -Default
  # Resets the list of wallpaper folders to the default.
#>

function Global:Set-Wallpaper {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string[]]$Path
  )
  if ($Path.Count -eq 1) {
    $singlePath = $Path[0]
    if (-not (Test-Path $singlePath)) {
      throw "Path not found: $singlePath"
    }
    $item = Get-Item $singlePath
    if ($item.PSIsContainer) {
      Write-Host "Path is a directory. Selecting a random wallpaper from '$singlePath'..."
      Set-RandomWallpaper -Folders $singlePath
    }
    else {
      Write-Host "Path is a file. Attempting to set '$singlePath' as wallpaper..."
      if (Set-WallpaperFromFile -FilePath $singlePath) {
        Register-Wallpaper
      }
    }
  }
  else {
    Write-Host 'Multiple paths provided. Searching for all available images...'
    $allImages = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $Path) {
      if (Test-Path $p) {
        $item = Get-Item $p
        if ($item.PSIsContainer) {
          $imagesInFolder = Get-ChildItem -Path $p -Recurse -Include '*.jpg', '*.jpeg', '*.png', '*.webp'
          if ($imagesInFolder) {
            $allImages.AddRange($imagesInFolder.FullName)
          }
        }
        else {
          $allImages.Add($item.FullName)
        }
      }
    }
    if ($allImages.Count -eq 0) {
      Write-Warning 'No valid image files were found in the provided paths.'
      return
    }
    $chosenImage = $allImages | Get-Random
    Write-Host "Randomly selected '$chosenImage'. Setting as wallpaper..."
    if (Set-WallpaperFromFile -FilePath $chosenImage) {
      Register-Wallpaper
    }
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
    if (Test-Path $defaultPath) {
      Set-UserEnvIfChanged 'DOTS_WALLPAPER' $defaultPath
      $dotsWallpaper = $defaultPath
    }
  }

  # Call helper functions in order of priority until a path is found.
  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      $wallpaperPath = Get-WallpaperFromJBS
      if (-not $wallpaperPath) { $wallpaperPath = Get-WallpaperFromRegistry }
      if (-not $wallpaperPath) { $wallpaperPath = Get-WallpaperFromSpotlight }
    }
    'Linux' {
      $wallpaperPath = Get-WallpaperFromGnome
      if (-not $wallpaperPath) { $wallpaperPath = Get-WallpaperFromKde }
      if (-not $wallpaperPath) { $wallpaperPath = Get-WallpaperFromXfce }
    }
    'MacOS' {
      $wallpaperPath = Get-WallpaperFromMacOs
    }
  }

  # Use the detected wallpaper; if none was found, use the fallback.
  $finalWallpaperPath = if ($wallpaperPath) { $wallpaperPath } else { $dotsWallpaper }
  if ($finalWallpaperPath) {
    Set-UserEnvIfChanged 'WALLPAPER' $finalWallpaperPath
    Set-WallpaperSymlink -NewWallpaperPath $finalWallpaperPath
  }
}

function Global:Set-Wallpapers {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Paths,
    [switch]$Default
  )
  if ($Default) {
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
    Write-Warning 'Please provide paths or use the -Default switch.'
  }
}

function Global:Register-Wallpapers {
  [CmdletBinding()]
  param()
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

function Global:Unregister-Wallpapers {
  [CmdletBinding()]
  param()
  if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('WALLPAPERS', $null, 'User')
  }
  Remove-Item 'env:WALLPAPERS' -ErrorAction SilentlyContinue

  Unregister-Wallpaper
}

function Global:Get-Wallpaper {
  <#
  .SYNOPSIS
    Gets the current wallpaper path, with options to refresh or target a specific source.
  .DESCRIPTION
    Retrieves the value of the '$env:WALLPAPER' variable. Includes a switch to force a
    full re-detection, and several switches to get the wallpaper path directly from a
    specific source like JBS, the Registry, or Spotlight, bypassing other checks.
  .PARAMETER Refresh
    If specified, runs the full Register-Wallpaper detection sequence before returning the path.
  .PARAMETER JBS
    Directly gets the wallpaper from John's Background Switcher, if available.
  .PARAMETER Registry
    Directly gets the wallpaper from the Windows Registry, if available.
  .PARAMETER Spotlight
    Directly gets the wallpaper from Windows Spotlight, if available.
  .PARAMETER Gnome
    Directly gets the wallpaper from GNOME's gsettings, if available.
  .PARAMETER Kde
    Directly gets the wallpaper from KDE's config file, if available.
  .PARAMETER Xfce
    Directly gets the wallpaper from XFCE's xfconf-query, if available.
  .PARAMETER MacOs
    Directly gets the wallpaper from macOS via osascript, if available.
  .EXAMPLE
    Get-Wallpaper
    # Returns the cached path from the environment variable.

  .EXAMPLE
    Get-Wallpaper -Refresh
    # Re-runs the full detection logic and returns the updated path.

  .EXAMPLE
    Get-Wallpaper -JBS
    # Bypasses other checks and attempts to get the path only from JBS.
  #>

  [CmdletBinding(DefaultParameterSetName = 'Default')]
  param(
    [Parameter(ParameterSetName = 'Refresh')]
    [switch]$Refresh,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [Alias('JohnsBackgroundSwitcher')]
    [switch]$JBS,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$Registry,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$Spotlight,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$Gnome,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$Kde,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$Xfce,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$MacOs
  )

  switch ($PSCmdlet.ParameterSetName) {
    'Refresh' {
      Register-Wallpaper
      return $env:WALLPAPER
    }
    'SpecificSource' {
      if ($JBS) { return Get-WallpaperFromJBS }
      if ($Registry) { return Get-WallpaperFromRegistry }
      if ($Spotlight) { return Get-WallpaperFromSpotlight }
      if ($Gnome) { return Get-WallpaperFromGnome }
      if ($Kde) { return Get-WallpaperFromKde }
      if ($Xfce) { return Get-WallpaperFromXfce }
      if ($MacOs) { return Get-WallpaperFromMacOs }
    }
    default {
      # 'Default' Parameter Set
      return $env:WALLPAPER
    }
  }
}

function Global:Open-Wallpaper {
  <#
  .SYNOPSIS
    Opens the current wallpaper image with the default system viewer.
  .DESCRIPTION
    A cross-platform utility that gets the wallpaper path and opens it using the
    appropriate system command, such as `xdg-open` on Linux or `open` on macOS.
  .EXAMPLE
    Open-Wallpaper
  #>

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

function Get-WallpaperFromJBS {
  $jbsPath = Join-Path $env:APPDATA 'johnsadventures.com' 'Background Switcher' 'LockScreen'
  if (Test-Path $jbsPath) {
    return Get-ChildItem -Path "$jbsPath\*.jpg" -Force -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -ExpandProperty FullName -First 1
  }
  return $null
}

function Get-WallpaperFromRegistry {
  try {
    $regPath = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -ErrorAction Stop |
    Select-Object -ExpandProperty Wallpaper
    if ($regPath -and (Test-Path $regPath)) { return $regPath }
  }
  catch {}
  return $null
}

function Get-WallpaperFromSpotlight {
  $assetsPath = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
  if (Test-Path $assetsPath) {
    return Get-ChildItem $assetsPath -File -ErrorAction SilentlyContinue |
    Where-Object Length -GT 100KB |
    Sort-Object Length -Descending |
    Select-Object -ExpandProperty FullName -First 1
  }
  return $null
}

function Get-WallpaperFromGnome {
  try {
    $uri = & gsettings get org.gnome.desktop.background picture-uri 2>$null
    $path = $uri.Trim("'") -replace '^file://'
    if ($path -and (Test-Path $path)) { return $path }
  }
  catch {}
  return $null
}

function Get-WallpaperFromKde {
  $kdeConfig = Join-Path $env:HOME '.config' 'plasma-org.kde.plasma.desktop-appletsrc'
  if (Test-Path $kdeConfig) {
    $configContent = Get-Content $kdeConfig -Raw -ErrorAction SilentlyContinue
    if ($configContent -match 'Image=file://([^\r\n]+)') {
      $path = $matches[1]
      if (Test-Path $path) { return $path }
    }
  }
  return $null
}

function Get-WallpaperFromXfce {
  try {
    $path = & xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image 2>$null
    if ($path -and (Test-Path $path)) { return $path }
  }
  catch {}
  return $null
}

function Get-WallpaperFromMacOs {
  try {
    $path = (& osascript -e 'tell application "Finder" to get POSIX path of (get desktop picture as alias)' 2>$null).Trim()
    if ($path -and (Test-Path $path)) { return $path }
  }
  catch {}
  return $null
}

function Set-UserEnvIfChanged {
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

function Set-WallpaperFromFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$FilePath
  )

  $success = $false
  $absolutePath = Convert-Path $FilePath

  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      try {
        $code = @'
        using System.Runtime.InteropServices;
        using Microsoft.Win32;
        public class Wallpaper {
          [DllImport("user32.dll", CharSet=CharSet.Auto)]
          public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
          public static void SetWallpaper(string path) {
            RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Control Panel\Desktop", true);
            key.SetValue(@"WallpaperStyle", 2.ToString()); // 2=Stretch
            key.SetValue(@"TileWallpaper", 0.ToString()); // 0=No
            SystemParametersInfo(20, 0, path, 3); // 20=SPI_SETDESKWALLPAPER, 3=SPIF_UPDATEINIFILE|SPIF_SENDCHANGE
          }
        }
'@
        Add-Type -TypeDefinition $code -ErrorAction Stop
        [Wallpaper]::SetWallpaper($absolutePath)
        $success = $true
      }
      catch {
        Write-Warning 'Failed to set wallpaper using the native Windows method.'
      }
    }
    'Linux' {
      if (Get-Command gsettings -ErrorAction SilentlyContinue) {
        & gsettings set org.gnome.desktop.background picture-uri "file://$absolutePath"
        $success = $true
      }
      elseif (Get-Command xfconf-query -ErrorAction SilentlyContinue) {
        & xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s $absolutePath
        $success = $true
      }
      else {
        Write-Warning 'Could not find a supported command (gsettings, xfconf-query) to set the wallpaper.'
      }
    }
    'MacOS' {
      try {
        $script = "tell application \`"System Events\`" to set picture of every desktop to POSIX file \`"$absolutePath\`""
        & osascript -e $script -ErrorAction Stop
        $success = $true
      }
      catch {
        Write-Warning 'Failed to set wallpaper using osascript.'
      }
    }
  }

  if ($success) {
    Write-Host "Wallpaper successfully set to: $absolutePath"
  }
  return $success
}

function Set-WallpaperFromFolders {
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

function Set-WallpaperWithJBS {
  [CmdletBinding()]
  param()

  # First, check if JBS is installed at all. Exit early if it's not.
  $jbsExe = @(
    (Join-Path $env:ProgramFiles 'johnsadventures.com' "John's Background Switcher" 'BackgroundSwitcher.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'johnsadventures.com' "John's Background Switcher" 'BackgroundSwitcher.exe')
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1

  if (-not $jbsExe) {
    return $false # JBS is not installed.
  }

  # Now that we know it's installed, check if it's running.
  $jbsProcess = Get-Process -Name 'BackgroundSwitcher' -ErrorAction SilentlyContinue
  if ($jbsProcess) {
    # --- JBS IS RUNNING: Send the keyboard shortcut ---
    try {
      Write-Host "JBS is running. Sending 'Next Picture' shortcut..."
      Add-Type -AssemblyName System.Windows.Forms
      $shell = New-Object -ComObject 'Shell.Application'; $shell.MinimizeAll()
      Start-Sleep -Milliseconds 250
      [System.Windows.Forms.SendKeys]::SendWait('^%n')
      Write-Host 'Wallpaper change triggered. JBS will update the environment.' -ForegroundColor Green
      return $true
    }
    catch {
      Write-Warning 'An error occurred while sending the keyboard shortcut.'
      return $false
    }
  }
  else {
    # --- JBS IS NOT RUNNING: Launch the application ---
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

function Set-WallpaperSymlink {
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

function Remove-WallpaperSymlink {
  [CmdletBinding()]
  param()
  $symlinkDir = if ($IsWindows) { Join-Path $env:USERPROFILE 'Pictures' } else { Join-Path $env:HOME 'Pictures' }
  $symlinkPath = Join-Path $symlinkDir 'wallpaper'
  if (Test-Path $symlinkPath) {
    Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
  }
}
