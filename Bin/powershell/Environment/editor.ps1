#@ PowerShell Editor Selection Script
#@ Usage: Dot-source this file to load editor functions

#region Editor Configuration
$script:EditorConfig = @{
  DefaultTuiEditors = @('hx', 'nvim', 'vim', 'nano', 'notepad')
  DefaultGuiEditors = @('code', 'code-insiders', 'zed', 'notepad++', 'sublime_text', 'atom')
  CurrentEditor     = $null
  Delimiter         = '|'
}
#endregion

#region Environment Detection
function Test-GuiEnvironment {
  <#
    .SYNOPSIS
    Determines if a GUI environment is available

    .DESCRIPTION
    Checks for GUI availability based on OS and environment variables
    - Windows: Always assumes GUI available
    - Unix/Linux: Checks for X11 (DISPLAY) or Wayland (WAYLAND_DISPLAY)
    - WSL: Checks for GUI forwarding support
    #>
  [CmdletBinding()]
  param()

  # Windows typically has GUI available
  if ($IsWindows -or $env:OS -like "*Windows*") {
    return $true
  }

  # Check for X11 or Wayland on Unix/Linux
  if ($env:DISPLAY -or $env:WAYLAND_DISPLAY) {
    return $true
  }

  # Check WSL with GUI support
  if ($env:WSL_DISTRO_NAME -and $env:DISPLAY) {
    return $true
  }

  return $false
}
#endregion

#region Editor Discovery
function Get-AvailableEditor {
  <#
    .SYNOPSIS
    Finds the first available editor from a list

    .PARAMETER EditorList
    Array of editor names to check

    .PARAMETER ReturnPath
    If specified, returns the full path instead of just the command name
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string[]]$EditorList,

    [switch]$ReturnPath
  )

  foreach ($editor in $EditorList) {
    if ([string]::IsNullOrWhiteSpace($editor)) { continue }

    try {
      $command = Get-Command $editor -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($command -and $command.Source -and (Test-Path $command.Source -PathType Leaf)) {
        return if ($ReturnPath) { $command.Source } else { $editor }
      }
    }
    catch {
      continue
    }
  }

  return $null
}

function Split-EditorString {
  <#
    .SYNOPSIS
    Splits an editor string into an array, handling multiple delimiters

    .PARAMETER EditorString
    String containing editor names separated by various delimiters

    .PARAMETER Delimiter
    Primary delimiter to normalize to (default: '|')
    #>
  [CmdletBinding()]
  param(
    [string]$EditorString,
    [string]$Delimiter = $script:EditorConfig.Delimiter
  )

  if ([string]::IsNullOrWhiteSpace($EditorString)) {
    return @()
  }

  # Normalize multiple delimiters: comma, pipe, colon, multiple spaces
  $normalized = $EditorString `
    -replace ',\s*', $Delimiter `
    -replace '\|\s*', $Delimiter `
    -replace ':\s*', $Delimiter `
    -replace '\s{2,}', $Delimiter `
    -replace '\s+', $Delimiter

  # Split and filter out empty/none values
  $editors = $normalized -split [regex]::Escape($Delimiter) | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne 'none'
  }

  return $editors
}
#endregion

#region Editor Selection
function Get-PreferredEditor {
  <#
    .SYNOPSIS
    Gets the preferred editor based on environment and configuration

    .PARAMETER CustomTuiEditors
    Custom TUI editors string (overrides environment/defaults)

    .PARAMETER CustomGuiEditors
    Custom GUI editors string (overrides environment/defaults)

    .PARAMETER ReturnPath
    Return full path instead of command name

    .PARAMETER Force
    Force re-evaluation even if editor is already cached
    #>
  [CmdletBinding()]
  param(
    [string]$CustomTuiEditors,
    [string]$CustomGuiEditors,
    [switch]$ReturnPath,
    [switch]$Force
  )

  # Return cached editor if available and not forcing re-evaluation
  if (-not $Force -and $script:EditorConfig.CurrentEditor -and -not $ReturnPath) {
    return $script:EditorConfig.CurrentEditor
  }

  # Get TUI editors from various sources (priority order)
  $tuiEditors = if ($CustomTuiEditors) {
    Split-EditorString $CustomTuiEditors
  }
  elseif ($env:EDITOR_TUI) {
    Split-EditorString $env:EDITOR_TUI
  }
  elseif ($env:EDITOR) {
    Split-EditorString $env:EDITOR
  }
  else {
    $script:EditorConfig.DefaultTuiEditors
  }

  # Get GUI editors from various sources (priority order)
  $guiEditors = if ($CustomGuiEditors) {
    Split-EditorString $CustomGuiEditors
  }
  elseif ($env:EDITOR_GUI) {
    Split-EditorString $env:EDITOR_GUI
  }
  elseif ($env:VISUAL) {
    Split-EditorString $env:VISUAL
  }
  else {
    $script:EditorConfig.DefaultGuiEditors
  }

  # Determine editor priority based on environment
  $editorList = if (Test-GuiEnvironment) {
    $guiEditors + $tuiEditors  # GUI first, TUI fallback
  }
  else {
    $tuiEditors  # TUI only in non-GUI environments
  }

  # Find first available editor
  $selectedEditor = Get-AvailableEditor -EditorList $editorList -ReturnPath:$ReturnPath

  if ($selectedEditor) {
    if (-not $ReturnPath) {
      $script:EditorConfig.CurrentEditor = $selectedEditor
    }
    return $selectedEditor
  }

  # Ultimate fallbacks
  $fallback = if ($IsWindows -or $env:OS -like "*Windows*") { 'notepad' } else { 'vi' }

  if (-not $ReturnPath) {
    $script:EditorConfig.CurrentEditor = $fallback
  }

  return $fallback
}

function Set-PreferredEditor {
  <#
    .SYNOPSIS
    Sets the preferred editor configuration

    .PARAMETER TuiEditors
    String of TUI editors in preference order

    .PARAMETER GuiEditors
    String of GUI editors in preference order
    #>
  [CmdletBinding()]
  param(
    [string]$TuiEditors,
    [string]$GuiEditors
  )

  # Clear cached editor to force re-evaluation
  $script:EditorConfig.CurrentEditor = $null

  # Get new preferred editor
  $newEditor = Get-PreferredEditor -CustomTuiEditors $TuiEditors -CustomGuiEditors $GuiEditors

  Write-Pretty -Tag "Verbose" "Editor preference updated: " -NoNewline
  Write-Pretty -Tag "Verbose" $newEditor -ForegroundColor Green

  return $newEditor
}
#endregion

#region Public Interface
function Invoke-Editor {
  <#
    .SYNOPSIS
    Launches the preferred editor with specified path/arguments

    .PARAMETER Path
    Path to open in the editor

    .PARAMETER Arguments
    Additional arguments to pass to the editor

    .PARAMETER Editor
    Override the default editor for this invocation
    #>
  [CmdletBinding()]
  param(
    [string]$Path = (Get-Location).Path,
    [string[]]$Arguments = @(),
    [string]$Editor
  )

  $editorToUse = if ($Editor) { $Editor } else { Get-PreferredEditor }
  $editorPath = Get-PreferredEditor -ReturnPath

  if (-not $editorToUse) {
    Write-Error "No suitable editor found"
    return
  }

  try {
    $allArgs = @($Path) + $Arguments
    Write-Pretty -Tag "Verbose" "Opening '$Path' with $editorToUse"

    & $editorToUse @allArgs
  }
  catch {
    Write-Warning "Failed to launch $editorToUse with path '$Path'. Error: $($_.Exception.Message)"

    # Try with full path if command name failed
    if ($editorPath -and $editorPath -ne $editorToUse) {
      try {
        & $editorPath @allArgs
      }
      catch {
        Write-Error "Failed to launch editor: $($_.Exception.Message)"
      }
    }
  }
}

function Show-EditorConfig {
  <#
    .SYNOPSIS
    Displays current editor configuration and available editors
    #>
  [CmdletBinding()]
  param()

  Write-Pretty -Tag "Verbose" "`n=== Editor Configuration ==="

  # Current editor
  $currentEditor = Get-PreferredEditor
  $currentPath = Get-PreferredEditor -ReturnPath
  $hasGui = Test-GuiEnvironment

  Write-Pretty -Tag "Verbose" `
    "Editor Name: $currentEditor" `
    "Editor Path: $currentPath" `
    "Environment: $(if ($hasGui) { "Graphical User Interface" } else { "Text User Interface" })"

  # Environment detection

  # Environment variables
  Write-Pretty -Tag "Verbose" "`nEnvironment Variables:"
  @('EDITOR_GUI', 'EDITOR_TUI', 'VISUAL', 'EDITOR') | ForEach-Object {
    $value = Get-Item "env:$_" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    Write-Pretty -Tag "Verbose" "  ${_}: " -NoNewline
    Write-Pretty -Tag "Verbose" $(if ($value) { $value } else { "(not set)" })
  }

  # Available editors
  Write-Pretty -Tag "Verbose" "`nAvailable Editors:"
  $allEditors = ($script:EditorConfig.DefaultGuiEditors + $script:EditorConfig.DefaultTuiEditors) | Sort-Object -Unique

  foreach ($editor in $allEditors) {
    $available = Get-Command $editor -ErrorAction SilentlyContinue
    $status = if ($available) { "✓" } else { "✗" }
    Write-Pretty -Tag "Verbose" "  $status $editor"
  }
}

function Set-EditorPreference {
  <#
    .SYNOPSIS
    Interactive editor preference configuration

    .PARAMETER Editor
    Set a single editor as preferred

    .PARAMETER TuiEditors
    Set TUI editors preference string

    .PARAMETER GuiEditors
    Set GUI editors preference string

    .PARAMETER Show
    Show current configuration
    #>
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = 'Single')]
    [string]$Editor,

    [Parameter(ParameterSetName = 'Separate')]
    [string]$TuiEditors,

    [Parameter(ParameterSetName = 'Separate')]
    [string]$GuiEditors,

    [Parameter(ParameterSetName = 'Show')]
    [switch]$Show
  )

  if ($Show -or (-not $Editor -and -not $TuiEditors -and -not $GuiEditors)) {
    Show-EditorConfig
    return
  }

  if ($Editor) {
    # Force single editor
    $script:EditorConfig.CurrentEditor = $Editor
    Write-Pretty -Tag "Verbose" "Editor set to: $Editor" -NoNewline
  }
  else {
    # Use intelligent selection with custom preferences
    Set-PreferredEditor -TuiEditors $TuiEditors -GuiEditors $GuiEditors
  }
}
#endregion

#region Initialization
# Initialize with intelligent editor selection
$script:EditorConfig.CurrentEditor = Get-PreferredEditor

# Export main functions for use in other scripts
Export-ModuleMember -Function @(
  'Get-PreferredEditor',
  'Set-PreferredEditor',
  'Invoke-Editor',
  'Show-EditorConfig',
  'Set-EditorPreference',
  'Test-GuiEnvironment'
)
#endregion
