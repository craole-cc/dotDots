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
function Get-WallpaperConfig {
  [CmdletBinding()]
  param()

  $dots = @{
    dir = [IO.Path]::Combine($env:DOTS, 'Assets', 'Images', 'wallpaper')
  }
  $dots.light = [IO.Path]::Combine($dots.dir, 'light.jpg')
  $dots.dark = [IO.Path]::Combine($dots.dir, 'dark.jpg')
  $dots.default = [IO.Path]::Combine($dots.dir, 'default.jpg')

  $dir = @{
    source = @(
      $dots.dir,
      ([IO.Path]::Combine('D:', 'Pictures', 'Wallpapers')),
      ([IO.Path]::Combine($env:USERPROFILE, 'Pictures', 'Wallpapers'))
    )
    target = if ($IsWindows) {
      [IO.Path]::Combine($env:USERPROFILE, 'Pictures')
    }
    else {
      [IO.Path]::Combine($env:HOME, 'Pictures')
    }
  }
  $sep = [IO.Path]::PathSeparator
  $jbs = @{
    exe  = @(
      ([IO.Path]::Combine($env:ProgramFiles, 'johnsadventures.com', "John's Background Switcher" , 'BackgroundSwitcher.exe')),
      ([IO.Path]::Combine(${env:ProgramFiles(x86)} , 'johnsadventures.com' , "John's Background Switcher" , 'BackgroundSwitcher.exe'))
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    path = [IO.Path]::Combine($env:APPDATA, 'johnsadventures.com', 'Background,Switcher', 'LockScreen')
  }
  $ref = [IO.Path]::Combine($dir.target, 'wallpaper')
  $ext = @{
    pattern = '\.(jpg|jpeg|png|webp|gif|bmp)$'
    include = '*.jpg', '*.jpeg', '*.png', '*.webp', '*.gif', '*.bmp'
  }

  return @{
    dots = $dots
    dir  = $dir
    sep  = $sep
    jbs  = $jbs
    ref  = $ref
    ext  = $ext
  }
}
function Get-WallpaperPersistMethod {
  <#
  .SYNOPSIS
    Gets the current wallpaper persist method, defaulting to 'link' if not set.
  .DESCRIPTION
    Returns the value of WALLPAPER_PERSIST_METHOD environment variable,
    or 'link' as the default if not set.
  #>
  [CmdletBinding()]
  param()

  if (-not $env:WALLPAPER_PERSIST_METHOD) {
    Set-WallpaperPersistMethod
  }
  return $env:WALLPAPER_PERSIST_METHOD.ToLower()
}
function Set-WallpaperPersistMethod {
  <#
  .SYNOPSIS
    Sets the wallpaper persist method to either 'Copy' or 'Link'.
  .DESCRIPTION
    Configures how the wallpaper reference file is created:
    - Copy: Creates a physical copy of the wallpaper file
    - Link: Creates a symbolic link to the wallpaper file (default)
    If called without parameters, ensures the default is set.
  .PARAMETER Method
    The persistence method to use: 'Copy' or 'Link'. If not specified, uses current value or defaults to 'Link'.
  .EXAMPLE
    Set-WallpaperPersistMethod -Method Copy
    # Sets the method to copy files
  .EXAMPLE
    Set-WallpaperPersistMethod -Method Link
    # Sets the method to create symbolic links
  .EXAMPLE
    Set-WallpaperPersistMethod
    # Ensures a default is set (Link) if nothing is configured
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [ValidateSet('Copy', 'Link')]
    [string]$Method
  )

  # If no method specified, check if env var is set
  if (-not $PSBoundParameters.ContainsKey('Method')) {
    if ($env:WALLPAPER_PERSIST_METHOD) {
      Write-Host "Current wallpaper persist method: $env:WALLPAPER_PERSIST_METHOD"
      return
    }
    else {
      # Set default
      $Method = 'Link'
      Write-Host "WALLPAPER_PERSIST_METHOD not set. Setting default to: $Method"
    }
  }
  else {
    # User explicitly set a method
    if ($env:WALLPAPER_PERSIST_METHOD -and $env:WALLPAPER_PERSIST_METHOD -ne $Method) {
      Write-Host "Changing wallpaper persist method from '$env:WALLPAPER_PERSIST_METHOD' to: $Method"
    }
    else {
      Write-Host "Setting wallpaper persist method to: $Method"
    }
  }

  Set-UserEnvIfChanged -Name 'WALLPAPER_PERSIST_METHOD' -Value $Method
}

function Set-Wallpaper {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string[]]$Path
  )

  $conf = Get-WallpaperConfig

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
          $imagesInFolder = Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue |
          Where-Object { $_.Extension -match $conf.ext.pattern }
          if ($imagesInFolder) { $allImages.AddRange($imagesInFolder.FullName) }
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
function Register-Wallpaper {
  [CmdletBinding()]
  param(
    [switch]$Dots
  )

  $wallpaper = $null
  $dotsWallpaper = Get-WallpaperFromDOTS

  if ($Dots) {
    $wallpaper = $dotsWallpaper
  }
  else {
    #~@ Detect current wallpaper based on platform
    switch (Get-OSPlatform) {
      'Windows' {
        $wallpaper = Get-WallpaperFromJBS
        if (-not $wallpaper) { $wallpaper = Get-WallpaperFromRegistry }
        if (-not $wallpaper) { $wallpaper = Get-WallpaperFromSpotlight }
      }
      { $_ -in @('Linux', 'WSL') } {
        $wallpaper = Get-WallpaperFromGnome
        if (-not $wallpaper) { $wallpaper = Get-WallpaperFromKde }
        if (-not $wallpaper) { $wallpaper = Get-WallpaperFromXfce }
      }
      'MacOS' {
        $wallpaper = Get-WallpaperFromMacOs
      }
    }
  }
  # Use detected wallpaper, or fall back to color-aware wallpaper
  $finalWallpaper = if ($wallpaper) { $wallpaper } else { $dotsWallpaper }
  Write-Pretty -NoNewLine -Tag 'Debug' "Wallpaper already loaded: $($finalWallpaper)"
  if ($finalWallpaper) {
    Set-UserEnvIfChanged -Name 'WALLPAPER' -Value $finalWallpaper
    Update-WallpaperReference
  }
}
function Set-Wallpapers {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Paths,
    [switch]$Default
  )

  $conf = Get-WallpaperConfig

  if ($Default) {
    Write-Host 'Resetting WALLPAPERS to default directories...'
    $existingFolders = $conf.dir.source | Where-Object { Test-Path $_ }
    if ($existingFolders) {
      $envValue = $existingFolders -join $conf.sep
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
      $envValue = $existingFolders -join $conf.sep
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
function Register-Wallpapers {
  [CmdletBinding()]
  param()
  $conf = Get-WallpaperConfig

  if (-not $env:WALLPAPERS) {
    Write-Host 'WALLPAPERS environment variable not set. Searching for default directories...'
    $existingFolders = $conf.dir.source | Where-Object { Test-Path $_ }
    if ($existingFolders) {
      $envValue = $existingFolders -join $conf.sep
      Write-Host "Setting WALLPAPERS default to: $envValue"
      Set-UserEnvIfChanged -Name 'WALLPAPERS' -Value $envValue
    }
  }
}
function Unregister-Wallpaper {
  [CmdletBinding()]
  param()

  #~@ Remove the physical reference file
  Remove-WallpaperReference

  #~@ Remove the environment variables
  if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('WALLPAPER', $null, 'User')
    [Environment]::SetEnvironmentVariable('WALLPAPER_DARK', $null, 'User')
    [Environment]::SetEnvironmentVariable('WALLPAPER_LIGHT', $null, 'User')
    [Environment]::SetEnvironmentVariable('WALLPAPER_VARIANT', $null, 'User')
    [Environment]::SetEnvironmentVariable('WALLPAPER_REFERENCE', $null, 'User')
  }

  Remove-Item 'env:WALLPAPER' -ErrorAction SilentlyContinue
  Remove-Item 'env:WALLPAPER_DARK' -ErrorAction SilentlyContinue
  Remove-Item 'env:WALLPAPER_LIGHT' -ErrorAction SilentlyContinue
  Remove-Item 'env:WALLPAPER_VARIANT' -ErrorAction SilentlyContinue
  Remove-Item 'env:WALLPAPER_REFERENCE' -ErrorAction SilentlyContinue
}
function Unregister-Wallpapers {
  [CmdletBinding()]
  param()
  if ($IsWindows) {
    [Environment]::SetEnvironmentVariable('WALLPAPERS', $null, 'User')
  }
  Remove-Item 'env:WALLPAPERS' -ErrorAction SilentlyContinue

  Unregister-Wallpaper
}
function Get-Wallpaper {
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
    [switch]$MacOs,

    [Parameter(ParameterSetName = 'SpecificSource')]
    [switch]$Dots
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
      if ($Dots) { return Get-WallpaperFromDOTS }
    }
    default {
      # 'Default' Parameter Set
      return $env:WALLPAPER
    }
  }
}
function Open-Wallpaper {
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

  # Pass all parameters from this function directly to Get-Wallpaper
  $wallpaperPath = Get-Wallpaper @PSBoundParameters

  if (-not $wallpaperPath -or -not (Test-Path $wallpaperPath)) {
    Write-Warning 'Wallpaper path could not be found or the file does not exist.'
    return
  }

  Write-Host "Opening: $wallpaperPath"
  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      Start-Process -FilePath $wallpaperPath
    }
    'Linux' {
      $openers = @('xdg-open', 'gio', 'gnome-open')
      foreach ($opener in $openers) {
        if (Get-Command $opener -ErrorAction SilentlyContinue) {
          Start-Process $opener $wallpaperPath
          return
        }
      }
      Write-Warning 'No known opener found to open the wallpaper image.'
    }
    'MacOS' {
      Start-Process -FilePath 'open' -ArgumentList $wallpaperPath
    }
  }
}
function Get-WallpaperFromJBS {
  $conf = Get-WallpaperConfig
  $path = $conf.jbs.path
  $exts = $conf.ext.include
  if (-not $path -or -not (Test-Path $path)) { return $null }
  try {
    return Get-ChildItem -Path $path -Force -Include $exts -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -ExpandProperty FullName -First 1
  }
  catch { return $null }
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
  if (-not (Test-Path $assetsPath)) {
    return $null
  }

  $spotlightAsset = Get-ChildItem $assetsPath -File -ErrorAction SilentlyContinue |
  Where-Object Length -GT 100KB |
  Sort-Object Length -Descending |
  Select-Object -First 1

  if (-not $spotlightAsset) {
    return $null
  }

  try {
    $tempImagePath = Join-Path ([IO.Path]::GetTempPath()) ($spotlightAsset.Name + '.jpg')
    Copy-Item -Path $spotlightAsset.FullName -Destination $tempImagePath -Force -ErrorAction Stop
    return $tempImagePath
  }
  catch {
    Write-Warning 'Failed to create a temporary copy of the Spotlight image.'
    return $null
  }
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
  $kdeConfig = [IO.Path]::Combine($env:HOME, '.config', 'plasma-org.kde.plasma.desktop-appletsrc')
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
function Get-WallpaperFromDOTS {
  [CmdletBinding()]
  param()

  $conf = Get-WallpaperConfig

  #~@ Ensure basic existence
  if (-not $conf.dots.path -or -not (Test-Path $conf.dots.path)) { return $null }
  if (-not $conf.dots.default -or -not (Test-Path $conf.dots.default)) {
    Write-Pretty -NoNewLine -Tag 'Error' "Missing default wallpaper: $($conf.dots.default)"
    return $null
  }

  #~@ Ensure dark/light fallback to default if missing
  if (-not (Test-Path $conf.dots.dark)) { $conf.dots.dark = $conf.dots.default }
  if (-not (Test-Path $conf.dots.light)) { $conf.dots.light = $conf.dots.default }

  #~@ Register variants if not already set
  Set-UserEnvIfChanged -Name 'WALLPAPER_LIGHT' -Value $conf.dots.light
  Set-UserEnvIfChanged -Name 'WALLPAPER_DARK' -Value $conf.dots.dark

  #~@ Choose variant from environment if present, otherwise system theme
  $variantPath = if (Get-DesktopColorMode -eq 'Dark') { $conf.dots.dark } else { $conf.dots.light }
  Write-Host "Using wallpaper variant: $($variantPath)"
  Set-UserEnvIfChanged -Name 'WALLPAPER_VARIANT' -Value $variantPath

  return (Test-Path $variantPath) ? $variantPath : $null
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

  # -- Configuration --
  $conf = Get-WallpaperConfig

  #~@ First, check if JBS is installed at all. Exit early if it's not.
  if (-not $conf.jbs.exe -or -not (Test-Path $conf.jbs.exe)) {
    return $false # JBS is not installed.
  }

  #~@ Now that we know it's installed, check if it's running.
  $jbsProcess = Get-Process -Name 'BackgroundSwitcher' -ErrorAction SilentlyContinue
  if ($jbsProcess) {
    #~@ JBS IS RUNNING: Send the keyboard shortcut
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
    #~@ JBS IS NOT RUNNING: Launch the application
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

function Update-WallpaperReference {
  [CmdletBinding()]
  param()

  # -- CONFIGURATION --
  try {
    $conf = Get-WallpaperConfig
  }
  catch {
    Write-Pretty -NoNewLine -Tag 'Error' "Failed to get wallpaper configuration`n$($_.Exception.Message)"
    return
  }

  if (-not (Test-Path $env:WALLPAPER)) {
    Write-Pretty -NoNewLine -Tag 'Error' "Source wallpaper file not found`n$env:WALLPAPER"
    return
  }

  #~@ Build source and target info
  $source = @{
    path = [IO.Path]::GetFullPath($env:WALLPAPER)
    ext  = [IO.Path]::GetExtension($env:WALLPAPER)
    hash = (Get-FileHash -Path $env:WALLPAPER -Algorithm SHA256).Hash
  }
  $target = @{
    path = [IO.Path]::GetFullPath($conf.ref)
    ext  = [IO.Path]::GetExtension($conf.ref)
    hash = if (Test-Path $conf.ref) {
      (Get-FileHash -Path $conf.ref -Algorithm SHA256).Hash
    }
    else { $null }
  }
  # Get the persist method (with default)
  $method = Get-WallpaperPersistMethod
  $needsUpdate = $false

  # -- Action --
  switch ($method) {
    'copy' {
      # -- Copy the file --
      #~@ Adjust target extension to match source
      if ($source.ext -ne $target.ext) {
        $target.path = [IO.Path]::ChangeExtension($target.path, $source.ext)
        #~@ Recalculate hash for the new target path
        $target.hash = if (Test-Path $target.path) {
          (Get-FileHash -Path $target.path -Algorithm SHA256).Hash
        }
        else { $null }
      }

      #~@ Determine if update is needed
      if (-not (Test-Path $target.path)) {
        $needsUpdate = $true
        Write-Pretty -NoNewLine -Tag 'Warn' 'Wallpaper reference file does not exist. Copy required.'
      }
      elseif ($source.hash -ne $target.hash) {
        $needsUpdate = $true
        Write-Pretty -NoNewLine -Tag 'Warn' 'Wallpaper reference file is outdated. Copy required.'
      }

      if ($needsUpdate) {
        try {
          Copy-Item -Path $source.path -Destination $target.path -Force -ErrorAction Stop
          Set-UserEnvIfChanged 'WALLPAPER_REFERENCE' $target.path
          Write-Pretty -Tag 'Success' `
            'Wallpaper copied successfully' `
            "Source: $($source.path)" `
            "Target: $($target.path)"
        }
        catch {
          Write-Pretty -NoNewLine -Tag 'Error' "Failed to copy wallpaper`n$($_.Exception.Message)"
          return
        }
      }
      else {
        Write-Pretty -NoNewLine -Tag 'Info' 'Wallpaper reference is already up-to-date.'
      }
    }

    'link' {
      # -- Create a symlink --
      #~@ Determine if an update is necessary
      if (Test-Path $target.path) {
        $path = Get-Item -Path $target.path -ErrorAction SilentlyContinue
        if ($path.LinkType -ne 'SymbolicLink') {
          $needsUpdate = $true
          Write-Pretty -NoNewLine -Tag 'Warn' 'Target exists but is not a symbolic link. Recreating.'
        }
        elseif ($path.Target -ne $source.path) {
          $needsUpdate = $true
          Write-Pretty -NoNewLine -Tag 'Warn' 'Symlink target differs. Update required.'
        }
      }
      else {
        $needsUpdate = $true
        Write-Pretty -NoNewLine -Tag 'Warn' 'Symlink does not exist. Creation required.'
      }

      #~@ Create or update the symlink, if needed
      if ($needsUpdate) {
        try {
          # Remove existing item if present (handles all cases reliably)
          if (Test-Path $target.path) {
            Remove-Item -Path $target.path -Force -ErrorAction Stop
          }

          # Create new symlink
          $null = New-Item -ItemType SymbolicLink -Path $target.path -Target $source.path -ErrorAction Stop
          Set-UserEnvIfChanged 'WALLPAPER_REFERENCE' $target.path
          Write-Pretty -Tag 'Success' `
            'Symlink created successfully' `
            "Source: $($source.path)" `
            "Target: $($target.path)"
        }
        catch {
          Write-Pretty -NoNewLine -Tag 'Error' "Failed to create symlink`n$($_.Exception.Message)"
          return
        }
      }
      else {
        Write-Pretty -NoNewLine -Tag 'Debug' 'Symlink is already up-to-date.'
      }
    }
    default {
      Write-Pretty -NoNewLine -Tag 'Error' "Invalid WALLPAPER_PERSIST_METHOD: '$method'.`nValid options are 'copy' or 'link'."
      return
    }
  }
}

<#
.SYNOPSIS
  (Internal) Removes the wallpaper reference file (symlink or copy).
.DESCRIPTION
  A helper function to clean up by deleting the '~/Pictures/wallpaper' reference file.
  It checks for both the symlink and potential copied files with extensions.
#>
function Remove-WallpaperReference {
  [CmdletBinding()]
  param()

  $conf = Get-WallpaperConfig

  # Remove the symlink if it exists
  $symlinkPath = $conf.ref
  if (Test-Path $symlinkPath) {
    Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
  }

  # Remove any copied files (e.g., wallpaper.jpg, wallpaper.png)
  $copiedFiles = Get-ChildItem -Path $conf.dir.source -Recurse -Filter 'wallpaper.*' |
  Where-Object { $_.Name -ne 'wallpaper' -and $_.Extension -match $conf.ext.pattern }
  if ($copiedFiles) {
    Remove-Item -Path $copiedFiles.FullName -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-Wallpaper {
  [CmdletBinding()]
  param()

  $success = $false

  switch -Wildcard ($PSVersionTable.OS) {
    '*Windows*' {
      Write-Host 'Attempting to change wallpaper on Windows...'
      if (Set-WallpaperWithJBS) { $success = $true }
      elseif (Set-WallpaperFromFolders) { $success = $true }
    }
    'Linux' {
      Write-Host 'Attempting to change wallpaper on Linux...'
      if (Set-WallpaperWithVariety) { $success = $true }
      elseif (Set-WallpaperFromFolders) { $success = $true }
    }
    'MacOS' {
      Write-Host 'Attempting to change wallpaper on macOS...'
      if (Set-WallpaperFromFolders) { $success = $true }
    }
  }

  if (-not $success) {
    Write-Warning 'Could not find a supported wallpaper manager or a local wallpaper to set.'
  }
}

Export-ModuleMember -Function 'Register-Wallpaper', 'Set-Wallpaper', 'Get-Wallpaper', 'Open-Wallpaper', 'Unregister-Wallpaper', 'Register-Wallpapers', 'Set-Wallpapers', 'Invoke-Wallpaper', 'Update-WallpaperReference', 'Remove-WallpaperReference', 'Set-WallpaperPersistMethod', 'Get-WallpaperPersistMethod', 'Get-WallpaperFromDOTS', 'Get-WallpaperConfig'
